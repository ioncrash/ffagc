class CreateAdmins < ActiveRecord::Migration[4.2]
  def change
    create_table :admins do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
