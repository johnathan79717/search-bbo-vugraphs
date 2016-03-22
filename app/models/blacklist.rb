class Blacklist < ActiveRecord::Base
  def self.add(id)
    if !exists? id
      Blacklist.new do |b|
        b.id = id
        b.save
      end
    end
  end

  def self.retry f
    delete(f.id)
    begin
      Vugraph.download!(f.id)
    rescue => e
      add(f.id)
      raise e
    end
  end

  def self.retry_first
    if count == 0
      puts 'Empty...'
    else
      Blacklist.retry first
    end
  end

  def self.retry_all
    all.each do |b|
      Blacklist.retry b
    end
  end
end
