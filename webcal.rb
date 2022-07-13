require 'sinatra'
require 'active_record'

set :environment, :production

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class Holiday < ActiveRecord::Base
  self.table_name = 'holidays'
end

def redirectToday()
  today = Time.now
  y = today.year
  m = today.month
  redirect "http://127.0.0.1:9998/#{y}/#{m}"
end


get '/' do
  redirectToday()
end

get '/:y/:m' do
  @nengo = ""
  #令和
  if params[:y].include?("R")
    begin
      paramy = Integer(params[:y][1, params[:y].length])
      paramm = Integer(params[:m])
    rescue
      redirectToday()
    end
    if (paramy == 1 && paramm < 5) || paramy < 1
      redirectToday()
    else
    @nengo = "（令和#{paramy}）"
    y = 2018 + paramy
    m = paramm
    end

  #平成
  elsif params[:y].include?("H")
    begin
      paramy = Integer(params[:y][1, params[:y].length])
      paramm = Integer(params[:m])
    rescue
      redirectToday()
    end
    if (paramy == 31 && paramm > 4) || paramy < 1
      redirectToday()
    elsif paramy > 31
      redirectToday()
    end
    @nengo = "（平成#{paramy}）"
    y = 1988 + paramy
    m = paramm

  #昭和
  elsif params[:y].include?("S")
    begin
      paramy = Integer(params[:y][1, params[:y].length])
      paramm = Integer(params[:m])
    rescue
      redirectToday()
    end
    if (paramy == 1 && paramm < 12) || paramy < 1
      redirectToday()
    elsif paramy == 64 && paramm != 1
      redirectToday()
    elsif paramy > 64
      redirectToday()
    end
    @nengo = "（昭和#{paramy}）"
    y = 1925 + paramy
    m = paramm

  #それ以外
  else
    begin
      y = Integer(params[:y])
      m = Integer(params[:m])
    rescue
      redirectToday()
    end
  end

  @year = y
  @month = m
  if @year < 0 || @month < 0 || @month > 12
    redirectToday()
  end

  @y1 = @year
  @m1 = @month - 1
  if @m1 == 0
    @m1 = 12
    @y1 = @y1 - 1
  end

  @y2 = @year
  @m2 = @month + 1
  if @m2 == 13
    @m2 = 1
    @y2 = @y2 + 1
  end

  @rainen = @year + 1
  @sakunen = @year - 1

  @t = "<table border>"
  @t = @t + "<tr><th>Sun</th><th>Mon</th><th>Tue</th><th>Wed</th>"
  @t = @t + "<th>Thu</th><th>Fri</th><th>Sat</th></tr>"

  l = getLastDay(@year, @month)
  h = zeller(@year, @month, 1)

  # 休日をDBから読み込む
  hol = Holiday.all
  holiday = Array.new(16){Array.new(2, 0)}
  hol.each_with_index do |c, i|
    holiday[i][0] = (c.date).split("-")[0].to_i
    holiday[i][1] = (c.date).split("-")[1].to_i
  end

  d = 1
  6.times do |p|
    @t = @t + "<tr>"
    7.times do |q|
      if p == 0 && q < h
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

          today = Time.now
          holiday_flag = 0
          holiday.each do |h|
            if @month == h[0] && d == h[1]
              @t = @t + "<td id=\"holiday\" align=\"right\"><strong>#{d}</strong></td>"
              holiday_flag = 1
            end
          end
          if @year == today.year && @month == today.month && d == today.day
            @t = @t + "<td id=\"today\" align=\"right\"><strong>#{d}</strong></td>"
          elsif holiday_flag == 0
            @t = @t + "<td align=\"right\"><font color=\"#{color}\">#{d}</font></td>"
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
