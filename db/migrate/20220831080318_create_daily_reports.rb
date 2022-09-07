class CreateDailyReports < ActiveRecord::Migration[7.0]
  def change
    create_table :daily_reports do |t|
      t.references :company, null: false, foreign_key: true
      t.float :price
      t.string :timestamp

      t.timestamps
    end
  end
end
