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
        @units = Unit.new(data['units'])
    end

	# def list_quaterly_report
 #    	units.filter {}.filter(&:quaterlyReport?)
 #    end
end

class Unit
	attr_accessor :forms

	def initialize(units = {})
		@forms = units["USD"].map { |obj| Form.new(obj) }
	end
end


class Form
   attr_accessor :end, :val, :accn, :fy, :fp, :form, :filed
   
   def initialize(form = {})
        @end = form['end']
        @val = form['val']
        @accn = form['accn']
        @fy = form['fy']
        @fp = form['fp']
        @form = form['form']
        @filed = form['filed']
    end

    def is10QReport?
        @form == '10-Q'
    end
end 