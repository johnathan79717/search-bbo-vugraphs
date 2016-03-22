class Player < ActiveRecord::Base
  attr_accessible :name
  has_many :players_boards, class_name: 'PlayersBoard'
  has_many :boards, through: :players_boards, class_name: 'Board'
end
