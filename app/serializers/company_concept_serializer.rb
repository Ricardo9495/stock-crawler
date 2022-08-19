class CompanyConceptSerializer < ActiveModel::Serializer
  attributes :cik, :taxonomy, :tag, :label, :description, :entityName
  attributes  :units

  # def list_quaterly_report
 #      units.filter {}.filter(&:quaterlyReport?)
 #    end
end

class Unit < ActiveModel::Serializer
  attributes :forms

  def initialize(units = {})
    @forms = units["USD"]
  end
end


class Form < ActiveModel::Serializer
  attributes :end
  attributes :val
  attributes :accn
  attributes :fy
  attributes :fp
  attributes :form
  attributes :filed
end 