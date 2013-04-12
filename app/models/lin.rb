require 'net/http'

class Lin < ActiveRecord::Base
  attr_accessible :body, :filename

  def self.download(linname)
    url = URI.parse("http://www.bridgebase.com/tools/vugraph_linfetch.php?id=#{linname}")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) do |http|
      http.request(req)
    end

    Lin.create(:body => res.body, :filename => linname)
  end
end
