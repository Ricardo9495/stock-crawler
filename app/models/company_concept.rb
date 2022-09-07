class CompanyConcept
	attr_accessor :cik, :taxonomy, :tag, :label, :description, :entityName
    attr_accessor :units

    def initialize(data = {})
        @cik = data['cik']
        @taxonomy = data['taxonomy']
        @tag = data['tag']
        @label = data['label']
        @description = data['description']
        @entityName = data['entityName']
        @units = Unit.new(data['units'], data['cik'])
    end

	# def list_quaterly_report
 #    	units.filter {}.filter(&:quaterlyReport?)
 #    end
end

class Unit
	attr_accessor :forms

	def initialize(units = {}, cik = '')
		@forms = units["USD"].map { |obj| Form.new(obj, cik) }
	end

    def report_by_year(year)
        return @forms.filter { |form| form.fy == year }.uniq {|f| f.accn }
    end
end


class Form
   attr_accessor :cik, :end, :val, :accn, :fy, :fp, :form, :filed, :primary_document_xml
   
   def initialize(form = {}, cik = '')
        @cik = cik
        @end = form['end']
        @val = form['val']
        @accn = form['accn']
        @fy = form['fy']
        @fp = form['fp']
        @form = form['form']
        @filed = form['filed']
    end

    def primary_document_xml_url
        acc_code = @accn.gsub('-', '')
        return "https://www.sec.gov/Archives/edgar/data/#{@cik}/#{acc_code}/#{@primary_document_xml}"
    end

    def is_10Q_report?
        @form == '10-Q'
    end

    def is_10K_report?
        @form == '10-K'
    end
end 