require 'sinatra'
require 'active_record'

set :environment, :production

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class Holiday < ActiveRecord::Base
  self.table_name = 'holidays'
end

class Birthday < ActiveRecord::Base
  self.table_name = 'birthdays'
end

def redirectToday()
  redirect "http://127.0.0.1:9998/#{Time.now.year}/#{Time.now.month}"
end

get '/' do
  redirectToday()
end

get '/:y/:m' do
  #令和
  if params[:y].include?("R")
    ry, rm = isValidNumber(params[:y], params[:m])
    y, m, @nengo = reiwa(ry, rm)

  #平成
  elsif params[:y].include?("H")
    hy, hm = isValidNumber(params[:y], params[:m])
    y, m, @nengo = heisei(hy, hm)

  #昭和
  elsif params[:y].include?("S")
    sy, sm = isValidNumber(params[:y], params[:m])
    y, m, @nengo = showa(sy, sm)

  else
    begin
      y, m = isValidNumber(params[:y], params[:m])
    rescue
      redirectToday()
    end
  end

  @y1, @m1 = sengetsu(y, m)
  @y2, @m2 = raigetsu(y, m)

  @rainen = y + 1
  @sakunen = y - 1

  @year = y
  @month = m

  l = getLastDay(@year, @month)
  zh = zeller(@year, @month, 1)

  # 休日をDBから読み込む
  hol = Holiday.all
  holiday = Array.new(hol.length){Array.new(0)}
  hol.each_with_index do |c, i|
    holiday[i].push(Date.parse(c.date.to_s).mon)
    holiday[i].push(Date.parse(c.date.to_s).day)
    holiday[i].push(c.desc)
  end

  bir = Birthday.all
  birthday = Array.new(bir.length){Array.new(0)}
  bir.each_with_index do |b, i|
    birthday[i].push(Date.parse(b.date.to_s).mon)
    birthday[i].push(Date.parse(b.date.to_s).day)
    birthday[i].push(b.desc)
  end

  @t = "<table border>"
  @t = @t + "<tr><th>Sun</th><th>Mon</th><th>Tue</th><th>Wed</th>"
  @t = @t + "<th>Thu</th><th>Fri</th><th>Sat</th></tr>"

  d = 1
  monholiday_flag = 0

  6.times do |p|
    @t = @t + "<tr>"
    7.times do |q|
      if p == 0 && q < zh
        @t = @t + "<td></td>"
      else
        if d <= l
          if q == 0
            color = "red"
          elsif q == 6
            color = "blue"
          else
            color = "black"
          end

          if monholiday_flag == 1
            @t = @t + "<td id=\"monholiday\" align=\"right\">#{d}</td>"
            monholiday_flag = 0
          else
            holiday_flag = 0
            holiday.each do |h|
              hday_m = h[0] # month
              hday_d = h[1] # day
              hdesc = h[2] # description
              if @month == hday_m && d == hday_d && whatDay(zh, d) == 0
                monholiday_flag = 1
              end
              if @month == hday_m && d == hday_d
                if whatDay(zh, d) == 6 #saturday
                  @t = @t + "<td class=\"tooltip\" id=\"satholiday\" align=\"right\">
                              <span class=\"tooltip-text\">#{hdesc}</span>
                                #{d}
                             </td>"
                elsif whatDay(zh, d) == 0 #sunday
                  @t = @t + "<td class=\"tooltip\" id=\"sunholiday\" align=\"right\">
                              <span class=\"tooltip-text\">#{hdesc}</span>
                                #{d}
                             </td>"
                else
                  @t = @t + "<td class=\"tooltip\" id=\"holiday\" align=\"right\">
                              <span class=\"tooltip-text\">#{hdesc}</span>
                                #{d}
                             </td>"
                end
                holiday_flag = 1
              end
            end

            birthday_flag = 0
            birthday.each do |b|
              bday_m = b[0] #month
              bday_d = b[1] #day
              bdesc = b[2] #description
              if @month == bday_m && d == bday_d
                if whatDay(zh, d) == 6 #saturday
                  @t = @t + "<td class=\"tooltip\" id=\"satbday\" align=\"right\">
                              <span class=\"tooltip-text\">#{bdesc}</span>
                                #{d}
                             </td>"
                elsif whatDay(zh, d) == 0 #sunday
                  @t = @t + "<td class=\"tooltip\" id=\"sunbday\" align=\"right\">
                              <span class=\"tooltip-text\">#{bdesc}</span>
                                #{d}
                             </td>"
                else
                  @t = @t + "<td class=\"tooltip\" id=\"bday\" align=\"right\">
                              <span class=\"tooltip-text\">#{bdesc}</span>
                                #{d}
                             </td>"
                end
                birthday_flag = 1
              end
            end

            today = Time.now
            if @year == today.year && @month == today.month && d == today.day
              @t = @t + "<td id=\"today\" align=\"right\"><strong>#{d}</strong></td>"
            elsif holiday_flag != 1 && birthday_flag != 1
              @t = @t + "<td align=\"right\"><font color=\"#{color}\">#{d}</font></td>"
            end
          end
          d += 1
        else
          @t = @t + "<td></td>"
        end
      end
    end
    @t = @t + "</tr>"
    if d > l
      break
    end
  end

  @t = @t + "</table>"
  erb :moncal
end

def isLeapYear(year)
  if year % 4 == 0
    if year % 100 == 0 && year % 400 != 0
      return false
    else
      return true
    end
  else
    return false
  end
end

def getLastDay(y, m)
  if m == 2
    if isLeapYear(y) == true
      return 29
    else
      return 28
    end
  elsif m == 4 || m == 6 || m == 9 || m == 11
    return 30
  else
    return 31
  end
end

def zeller(y, m, d)
  if m == 1 || m == 2
    y = y - 1
    m = m + 12
  end
  h = y + y/4 - y/100 + y/400 + (13*m + 8)/5 + d
  return h % 7
end

def whatDay(zh, d)
  return (zh + d - 1) % 7
end

def isValidNumber(y, m)
  begin
    if y.include?("S") || y.include?("H") || y.include?("R")
      paramy = Integer(y[1, y.length])
      paramm = Integer(m)
    else
      paramy = Integer(y)
      paramm = Integer(m)
    end
    isValidYearMonth(paramy, paramm)
    return paramy, paramm
  rescue
    redirectToday()
  end
end

def isValidYearMonth(y, m)
  if y < 0 || m < 0 || m > 12
    redirectToday()
  end
end

def sengetsu(y, m)
  if m-1 == 0
    return y - 1, 12
  else
    return y, m - 1
  end
end

def raigetsu(y, m)
  if m + 1 == 13
    return y + 1, 1
  else
    return y, m + 1
  end
end

def reiwa(y, m)
  if (y == 1 && m < 5) || y < 1
    redirectToday()
  else
    return 2018 + y, m, "（令和#{y}）"
  end
end

def heisei(y, m)
  if (y == 31 && m > 4) || y < 1
    redirectToday()
  elsif y > 31
    redirectToday()
  else
    return 1988 + y, m, "（平成#{y}）"
  end
end

def showa(y, m)
  if (y == 1 && m < 12) || y < 1
    redirectToday()
  elsif y == 64 && m != 1
    redirectToday()
  elsif y > 64
    redirectToday()
  else
    return 1925 + y, m, "（昭和#{y}）"
  end
end
