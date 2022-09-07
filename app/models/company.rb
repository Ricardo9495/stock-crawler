class Company < ApplicationRecord
	has_many :quater_reports
	has_many :daily_reports
end
