class Board < ActiveRecord::Base
  attr_accessible :number, :players, :hands, :auction, :explanation, :event

end