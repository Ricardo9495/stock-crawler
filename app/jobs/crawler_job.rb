require 'rest-client'
require 'json'
require 'nokogiri'
require 'open-uri'

class CrawlerJob
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
  attr_accessor :cik, :year, :doc, :submission
 
  COOKIE = 'ak_bmsc=E58029CED0CBAA7FEAE61B5BD151F626~000000000000000000000000000000~YAAQLNo4fVozkYaCAQAAhZsTpBCjw70DAsUy2OdlS9n7WCJcghNMY3JHM5t7TG5GTAWIwB/PBHruqKUcbBPfNsKDZ2A3IMQgXzk27/1VCeKN/aKz4nDALAMAN2iXPd/VSLqe9YPzbUoKTkR9Fj/mOa30v71pnvCgV6/vtNNcLENErzxRfJ3ijBsENGS3JoChMkIlpHwehLjM9SuA/YL5DnpeZ+f6k+Km94vXvRsiEI8hvpZr13mvFAghIRZJGSVaTtIWhiXkc49DU9yKugnZfIK/l+p3DibC9IjdtRgOBMAjzuUKV7toL0zgy0by4yDZ1qUFwAoo1YLZhqPDI5ToJ5cUQxPmyNumBQ0nqPZAXMUFM4zErB1fETE='

  def initialize(cik, year)
    @cik = cik
    @year = year
  end

  def company
    @company ||= Company.find_by cik: @cik
  end
  
  def list_quaterly_report_by_year
    begin

      url = "https://data.sec.gov/api/xbrl/companyconcept/#{formatted_cik}/us-gaap/AccountsPayableCurrent.json"
      puts "url:#{url}";
      response = RestClient.get(url, {:cookies => {:ak_bmsc => COOKIE}})
      concepts = CompanyConcept.new(JSON.parse(response))

      reports = concepts.units.report_by_year(@year)
      puts "reports:#{reports.map(&:accn)}";

      persit_reports(reports)
    rescue StandardError => e
      puts "exceptions: #{e}"
    end
  end
  

  def persit_reports(reports)
    quater_reports = []
    reports.select(&:is_10Q_report?).each do |report|
        set_primary_document(report)
        quater_report = extract_data_from_report(report)
        quater_reports.push(quater_report)
    end

    last_quater_report = last_quater_report(reports, quater_reports)

    quater_reports.push(last_quater_report) if (last_quater_report)

    quater_reports.each do |report|
      report.save
      persit_daily_report(report)
    end
  end


  def last_quater_report(reports, quater_reports)
    anual_report = anual_report(reports)

    return if (!anual_report)

    total_three_quater_eps = quater_reports.map(&:earning_per_share).sum
    total_three_quater_net_income = quater_reports.map(&:net_income).sum

    # total_three_quater_equity = quater_reports.map(&:equity).sum

    # total_three_quater_sos = quater_reports.map(&:share_out_standing).sum

    # total_three_quater_net_d_d_a_p = quater_reports.map(&:d_d_a_p).sum

    # total_three_quater_net_ltdc = quater_reports.map(&:long_term_debt_current).sum

    # total_three_quater_net_ltdnc = quater_reports.map(&:long_term_debt_non_current).sum

    # total_three_quater_net_cp = quater_reports.map(&:commercial_paper).sum


    third_quater_report = quater_reports.find { |report| report.quater == 'Q3' }
    start_date = DateTime.parse(third_quater_report.end_date) + 1.day

    puts "Q4-start-date:#{start_date}"
    puts "Q4-end_date:#{DateTime.parse(anual_report.end_date)}"

    return QuaterReport.new(
        company_id: company.id,
        quater: 'Q4',
        start_date: start_date,
        end_date: DateTime.parse(anual_report.end_date),
        equity: anual_report.equity,
        earning_per_share: anual_report.earning_per_share - total_three_quater_eps,
        share_out_standing: anual_report.share_out_standing,
        net_income: anual_report.net_income - total_three_quater_net_income,
        d_d_a_p: anual_report.d_d_a_p,
        long_term_debt_current: anual_report.long_term_debt_current,
        long_term_debt_non_current: anual_report.long_term_debt_non_current,
        commercial_paper: anual_report.commercial_paper
      )

    quater_reports.push(last_quater_report)
  end


  def persit_daily_report(report)
    begin
      puts "in persit_daily_report"
      start_date = Date.parse(report.start_date).to_time.to_i
      end_date = Date.parse(report.end_date).to_time.to_i

      url = "https://query1.finance.yahoo.com/v8/finance/chart/#{company.ticker}?metrics=close&interval=1d&period1=#{start_date}&period2=#{end_date}"

      response = RestClient.get(url)
      data = JSON.parse(response)

      time_stamps = data["chart"]["result"][0]["timestamp"]
      prices = data["chart"]["result"][0]["indicators"]["adjclose"][0]["adjclose"]

      time_stamps.each_with_index do |time, index|
        daily_report = DailyReport.new(company_id: company.id, price: prices[index].to_f, timestamp: Time.at(time.to_i).to_datetime)
        daily_report.save
      end

    rescue StandardError => e
      puts "exceptions: #{e}"
    end
  end

  def anual_report(reports)
    anual_report = reports.find(&:is_10K_report?)
    return if (!anual_report)

    set_primary_document(anual_report)

    return extract_data_from_report(anual_report)
  end


  def extract_data_from_report(report)
    begin
      throw StandardError.new('URL path is empty') if (report.primary_document_xml_url.empty?)

      @doc = Nokogiri::XML(URI.open(report.primary_document_xml_url, "Cookie" => COOKIE)) 

      # @doc = Nokogiri::XML(File.open(url))

      # EPS
      earning_per_share_dilluted = text_from_xpath('us-gaap:EarningsPerShareDiluted').to_f

      # Equity
      equity = demical_from_xpath('us-gaap:StockholdersEquity').to_i

      # Share out standing
      share_out_standing = demical_from_xpath('us-gaap:WeightedAverageNumberOfDilutedSharesOutstanding').to_i

      # net income
      net_income = demical_from_xpath('us-gaap:NetIncomeLoss').to_i

      #Depreciation, Depletion And Amortization
      d_d_a_p = demical_from_xpath('us-gaap:DepreciationDepletionAndAmortization').to_i

      # Long Term Debt Current
      long_term_debt_current = demical_from_xpath('us-gaap:LongTermDebtCurrent').to_i

      # Long Term Debt Non Current
      long_term_debt_non_current = demical_from_xpath('us-gaap:LongTermDebtNoncurrent').to_i

      # CommercialPaper
      commercial_paper = demical_from_xpath('us-gaap:CommercialPaper').to_i

      eps_id = @doc.xpath('/*/us-gaap:EarningsPerShareDiluted[1]')[0].attributes['contextRef'].value
      period = @doc.search("context[id='#{eps_id}'] > period")[0]
      start_date = period.search('startDate')[0].children[0].text
      end_date = period.search('endDate')[0].children[0].text


      quater_report = QuaterReport.new(
        company_id: company.id,
        quater: report.fp,
        start_date: DateTime.parse(start_date),  # how
        end_date: DateTime.parse(end_date),   # how
        equity: equity,
        earning_per_share: earning_per_share_dilluted,
        share_out_standing: share_out_standing,
        net_income: net_income,
        d_d_a_p: d_d_a_p,
        long_term_debt_current: long_term_debt_current,
        long_term_debt_non_current: long_term_debt_non_current,
        commercial_paper: commercial_paper
      )

    rescue StandardError => e
      puts "exceptions: #{e}"
    end
  end

  def text_from_xpath(path = '')
    return '' if (path.empty?)

    return @doc.xpath('/*/' + path + '[1]')[0].text
  end

  def demical_from_xpath(path = '')
    return '' if (path.empty?)

    node = @doc.xpath('/*/' + path + '[1]')[0]

    return '' if (!node)

    text = node.text
    demical = node.attributes['decimals'].value.to_i

    return text.insert(-1 + demical, '.')
  end

  def set_primary_document(report)
    index_of_accn = accession_numbers.index(report.accn)

    primary_document = primary_documents[index_of_accn]

    report.primary_document_xml = primary_document.gsub('.htm', '_htm.xml')
  end

  def submission
    return @submission if (@submission)

    subUrl = "https://data.sec.gov/submissions/#{formatted_cik}.json"
    puts "subUrl:#{subUrl}"
    response = RestClient.get(subUrl, {:cookies => {:ak_bmsc => COOKIE}})
    puts "submission: response:#{response}"
    
    return if (!response)

    @submission = JSON.parse(response)

    return @submission
  end

  def accession_numbers
    return @accessionNumbers ||= submission && submission["filings"] && submission["filings"]["recent"] && submission["filings"]["recent"]["accessionNumber"] ? submission["filings"]["recent"]["accessionNumber"] : nil
  end

  def primary_documents
    return @primaryDocuments ||= submission && submission["filings"] && submission["filings"]["recent"] && submission["filings"]["recent"]["primaryDocument"] ? submission["filings"]["recent"]["primaryDocument"] : nil
  end

  def formatted_cik
    @formatted_cik ||= "CIK#{'0'*(10 - @cik.to_s.length)}#{@cik}"
  end

end




