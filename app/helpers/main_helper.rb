module MainHelper

  def dealer(number)
    case number % 4
    when 1; 'North'
    when 2; 'East'
    when 3; 'South'
    else;   'West'
  end

  def vul(number)
    case (number / 4 + number) % 4
    when 1; 'None'
    when 2; 'N/S'
    when 3; 'E/W'
    else;   'All'
  end
end
