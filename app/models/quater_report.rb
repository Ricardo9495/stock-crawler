class QuaterReport < ApplicationRecord
	attr_accessor :quater, :start_date, :end_date, :earning_per_share, :share_out_standing, :net_income, :d_d_a_p, :long_term_debt_current, :long_term_debt_non_current, :commercial_paper

	def initialize(quater, start_date, end_date, earning_per_share, share_out_standing, net_income, d_d_a_p, long_term_debt_current, long_term_debt_non_current, commercial_paper)
		@quater = quater
		@start_date = start_date
		@end_date = end_date
		@earning_per_share = earning_per_share
		@share_out_standing = share_out_standing
		@net_income = net_income
		@d_d_a_p = d_d_a_p
		@long_term_debt_current = long_term_debt_current
		@long_term_debt_non_current = long_term_debt_non_current
		@commercial_paper = commercial_paper
	end
end
