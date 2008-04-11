class TrackbackPluginMigration < ActiveRecord::Migration
  def self.up
    create_table :trackbacks do |t|
      t.string :trackable_type, :ip, :title, :url, :blog_name, :excerpt
      t.integer :trackable_id
      t.boolean :approved, :default => false
      t.timestamps
    end
  end
  
  def self.down
    drop_table :trackbacks
  end
end
