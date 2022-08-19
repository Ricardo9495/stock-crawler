# require 'rest-client'
# require 'json'
# require 'nokogiri'

class CrawlerJob
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
  attr_accessor :cik, :year, :doc
 
  COOKIE = 'ak_bmsc=E58029CED0CBAA7FEAE61B5BD151F626~000000000000000000000000000000~YAAQLNo4fVozkYaCAQAAhZsTpBCjw70DAsUy2OdlS9n7WCJcghNMY3JHM5t7TG5GTAWIwB/PBHruqKUcbBPfNsKDZ2A3IMQgXzk27/1VCeKN/aKz4nDALAMAN2iXPd/VSLqe9YPzbUoKTkR9Fj/mOa30v71pnvCgV6/vtNNcLENErzxRfJ3ijBsENGS3JoChMkIlpHwehLjM9SuA/YL5DnpeZ+f6k+Km94vXvRsiEI8hvpZr13mvFAghIRZJGSVaTtIWhiXkc49DU9yKugnZfIK/l+p3DibC9IjdtRgOBMAjzuUKV7toL0zgy0by4yDZ1qUFwAoo1YLZhqPDI5ToJ5cUQxPmyNumBQ0nqPZAXMUFM4zErB1fETE='

  def initialize(cik, year)
    @cik = cik
    @year = year
  end

  
  def list_quaterly_report_by_year
    begin
      url = "https://data.sec.gov/api/xbrl/companyconcept/#{@cik}/us-gaap/AccountsPayableCurrent.json"
      puts "url:#{url}";
      response = RestClient.get(url, {:cookies => {:ak_bmsc => COOKIE}})
      concepts = CompanyConcept.new(JSON.parse(response))


      return concepts.list_quaterly_report_by_year(@year).map(&:accn).uniq
    rescue StandardError => e
      puts "exceptions: #{e}"
    end
  end

  def extract_data_from_report(file = '')
    begin
      throw StandardError.new('File path is empty') if (file.empty?)

      @doc = Nokogiri::XML(File.open(file))

      # EPS
      earning_per_share_dilluted = text_from_xpath('us-gaap:EarningsPerShareDiluted')

      # Equity
      equity = demical_from_xpath('us-gaap:StockholdersEquity')

      # Share out standing
      share_out_standing = text_from_xpath('us-gaap:WeightedAverageNumberOfDilutedSharesOutstanding')

      # net income
      net_income = demical_from_xpath('us-gaap:NetIncomeLoss')

      #Depreciation, Depletion And Amortization
      d_d_a_p = demical_from_xpath('us-gaap:DepreciationDepletionAndAmortization')

      # Long Term Debt Current
      long_term_debt_current = demical_from_xpath('us-gaap:LongTermDebtCurrent')

      # Long Term Debt Non Current
      long_term_debt_non_current = demical_from_xpath('us-gaap:LongTermDebtNoncurrent')

      # CommercialPaper
      commercial_paper = demical_from_xpath('us-gaap:CommercialPaper')
      
      quater_report = QuaterReport.new('Q2', enquity, earning_per_share_dilluted, equity, share_out_standing, net_income, d_d_a_p, long_term_debt_current, long_term_debt_non_current, commercial_paper, DateTime.parse('2021-12-26'), DateTime.parse('2021-03-26')

      quater_report.save!
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

end
