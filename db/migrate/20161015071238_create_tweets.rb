class CreateTweets < ActiveRecord::Migration[5.0]
  def change
    create_table(:tweets, id: false) do |t|
      t.integer :status_id , limit: 32, primary_key: true
      t.string :created_at
      t.text :text
      t.string :media
      t.string :source
      t.integer :in_reply_to_status_id , limit: 32
      t.string :user_screen_name
      t.string :user_profile_image
      t.string :tag
      t.text :memo

      t.timestamps
    end
    #execute "ALTER TABLE tweets ADD PRIMARY KEY (status_id);"
  end
end
