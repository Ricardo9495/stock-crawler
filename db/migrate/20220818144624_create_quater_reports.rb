class CreateQuaterReports < ActiveRecord::Migration[7.0]
  def change
    create_table :quater_reports do |t|
      t.string :quater
      t.string :start_date
      t.string :end_date
      t.integer :earning_per_share
      t.integer :share_out_standing
      t.integer :net_income
      t.integer :d_d_a_p
      t.integer :long_term_debt_current
      t.integer :long_term_debt_non_current
      t.integer :commercial_paper

      t.timestamps
    end
  end
end
