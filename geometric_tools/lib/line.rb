# Copyright (c)  2008 Sandra Placzek (sandra@lifewizz.com)
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

require 'point'

module GeometricTools
  
    class Line
    
    attr_accessor :startpoint, :endpoint, :box, :xI, :xF, :yI, :yF
    attr_reader :slope, :intercept
              
    @@lines_by_original_position = {}
    @@lines = []
    @@settled_lines={}
  
    def self.lines
      @@lines
    end
  
    def self.reset
      @@lines_by_original_postion = {}
      @@lines = []
    end
    
    # startpoint, endpoint -> Object of class point

    def initialize _startpoint, _endpoint
      @startpoint = Point.new _startpoint.x, _startpoint.y
      @endpoint   = Point.new _endpoint.x,   _endpoint.y
  
      
      if (@endpoint.x - @startpoint.x) != 0
        @slope = (@endpoint.y - @startpoint.y).to_f/(@endpoint.x - @startpoint.x)
        @intercept = @startpoint.y - @slope*@startpoint.x
      else @slope = "endless"
      end
      
      attributes_for_line_in_right_direction
  
      @box = Box.new self
  
      if @startpoint != @endpoint
        if values_array = @@lines_by_original_position[@startpoint]
          raise "one point can only be shared by two lines" if values_array.size > 1
          values_array << self
        else
          @@lines_by_original_position[@startpoint] ==self
        end
        @@lines << self
      end
  
      if self.startpoint.is_equal?(self.endpoint)
        @@lines.delete(self)
        @@lines_by_original_position.delete(self)
      end
  
    end

    #divides one lin into two lines at given x- coordinate  
    def chop_line_at_given_x _given_x
      point = Point.new(_given_x, get_y_for_given_x_on_line(_given_x))
      lineA = Line.new(@startpoint, point)
      lineB = Line.new(point, @endpoint)
      [lineA, lineB]
    end
  
    def self.settled_lines
      @@settled_lines
    end

    # finds all lines that are connected  
    def self.sat_night
      busy_lines = {}
      Line.lines.each do |line|
        unless busy_lines.has_key? line
          busy_lines[line] = true
          hunting_chain line,  busy_lines
          line.box.included_lines.each {|settled_line| @@settled_lines[settled_line] = true}
        end
      end
    end
  
    #finds closest line
    def self.hunting_chain _line, _busy_lines
      while victim = _line.pickup_closest_line
        raise "victim is already game" if _line.box.has_line?(victim)
        _line.befriend! victim, _busy_lines 
        _busy_lines[victim] = true
        _line = victim
      end
    end
  
    def is_vertical?
      @xI == @xF
    end
    
    def is_horizontal?
      @yI == @yF
    end

    def jump_into_new_box! _new_box
      _new_box << self
      @box = _new_box
    end
  
    #finds the closest line
    def pickup_closest_line 
      victim = nil
      conflict_flag = false
  
      all_other_non_settled_lines.each do |line|
          if victim 
            case compare_distances line, victim
            when :longer
              victim = line
              conflict_flag = false
            when :equal
  
              conflict_flag = true
            end
          else
            victim = line
          end
      end
  
      raise "You can only have one closest line! #{self.inspect}" if conflict_flag
     
      @box.has_line?(victim) ? nil : victim 
    end
  
  
    def settle_lines
      flag=false
      @box.included_lines.each do |line|
        if line.closest_line==nil
          flag=true
        else
          flag=false
        end
      end
      if flag
        @box.included_lines.each do |settled_line|
          @@settled_lines << settled_line
          end
      end
    end
  
    #a line is adjusted if the x coordinate of the startpoint is lower than the x coordinate of the endpoint
    def adjusted?
      (@startpoint.x < @endpoint.x) ? true : false
    end
  
    def adjust!
      if @startpoint.x > @endpoint.x
        flip!
      elsif (@startpoint.x == @endpoint.x) && (@startpoint.y > @endpoint.y)
        flip!
      end    
      self
    end
  
    #changes the direction of a line
    def flip!
      (@startpoint, @endpoint) = [@endpoint, @startpoint]
      (@xI, @xF, @yI, @yF) = [@xF, @xI, @yF, @yI]
    end
  
    # A line can only befriend one and just one line that is close to the endpoint.
    # The new friend is invited to come and sleep in my box, but it may need to change orientation first
    # If the new friend already has a friend, then they all come to my box.
    def befriend! _new_friend, _busy_lines
      compatible_attitude = friend_compatibility_test _new_friend
      
      unless compatible_attitude
        _new_friend.flip!
        closing_line = close_gap_to_line _new_friend
        _new_friend.flip!
      end
      if compatible_attitude
        closing_line = close_gap_to_line _new_friend
      end
  
        closing_line.box.drop_lines 
        @@lines.delete(closing_line)
  
  
      _new_friend.box.drop_lines.each do |line|
        line.flip! unless compatible_attitude
        unless @box.has_line? closing_line
          closing_line.jump_into_new_box! @box 
        end
        line.jump_into_new_box! @box
      end
      @box.delete_double_lines
    end
  
     # adjusts _line1 start and end point in order to have _line1 snapped to _line2
     def snap_to _line1, _line2
       (adj_x, adj_y) = distance_to _line1.startpoint, _line2.endpoint
       _line1.startpoint.adjust adj_x, adj_y
       _line1.endpoint.adjust adj_x, adj_y
     end
     
    def get_y_for_given_x_on_line _given_x
      @slope * _given_x + @intercept
    end
  
    def inspect
      "xi: #@xI; yi: #@yI; xf: #@xF; yf: #@yF; startpoint: #{@startpoint.inspect}; endpoint: #{@endpoint.inspect}"
    end
  
    def has_line_two_friends?
      startpoint_has_friend = false
      endpoint_has_friend = false
      box = self.box
      box.included_lines.each do |line, value|
        unless line == self
          self.startpoint.is_equal?(line.startpoint) ? (startpoint_has_friend = true) : nil
          self.startpoint.is_equal?(line.endpoint) ? (startpoint_has_friend = true) : nil
          self.endpoint.is_equal?(line.startpoint) ? (endpoint_has_friend = true) : nil
          self.endpoint.is_equal?(line.endpoint) ? (endpoint_has_friend = true) : nil
        end
      end
      (startpoint_has_friend && endpoint_has_friend) ? true : false
    end
  
  
    def close_gap_to_line _line
      if (intersection = intersection_with_line _line)
        if (Point.euc_distance(intersection, self.endpoint) < Point.euc_distance(intersection, self.startpoint))
        
          self.endpoint = intersection
          self.xF = intersection.x
          self.yF = intersection.y
        else
          self.startpoint = intersection
          self.xI = intersection.x
          self.yI = intersection.y
        end
        if (Point.euc_distance(intersection, _line.endpoint) < Point.euc_distance(intersection, _line.startpoint))
          _line.endpoint = intersection
          _line.xF = intersection.x
          _line.yF = intersection.y
        else
  
          _line.startpoint = intersection
          _line.xI = intersection.x
          _line.yI = intersection.y
        end
      end
      closing_line = Line.new self.endpoint, _line.startpoint  
    end
  
    protected
  
    def intersection_with_line _line
      m1 = self.slope
      b1 = self.intercept
      m2 = _line.slope
      b2 = _line.intercept
       
      unless m1 == m2
        if !b1
          x = self.xI
          y = m2*x + b2
        elsif !b2
          x = _line.xI
          y = m1*x + b1
        else
          x = (b2-b1)/(m1-m2)
          y = m1*x + b1
        end
        intersection = Point.new(x,y)
      end
    end
  
    
    def attributes_for_line_in_right_direction
        @xI = @startpoint.x 
        @yI = @startpoint.y
        @xF = @endpoint.x
        @yF = @endpoint.y
    end
  
    def attributes_for_line_in_wrong_direction
        @xI = @endpoint.x
        @yI = @endpoint.y
        @xF = @startpoint.x 
        @yF = @startpoint.y
    end
  
    # returns whether distance to _tgt2 is [:longer | :equal | :shorter] than the distance to _tgt1
    def compare_distances _tgt1, _tgt2
      (dst1, dst2) = [distance_to_line(_tgt1), distance_to_line(_tgt2)]
  
      if dst2 > dst1
        :longer
      elsif dst2 < dst1
        :shorter
      else
        :equal
      end
    end
  
    def all_other_non_settled_lines
      @@lines.find_all {|line| (line != self) && !@@settled_lines[line]}
    end
  
    def distance_to_line _line
      raise "why do you give me a nil line? willst du mich verarschen?" unless _line
      tail_to_head = Point.euc_distance(@endpoint, _line.startpoint)
      tail_to_tail = Point.euc_distance(@endpoint, _line.endpoint)
      tail_to_head > tail_to_tail ? tail_to_tail : tail_to_head
    end
      
    def friend_compatibility_test _dubious_friend
      Point.euc_distance(_dubious_friend.startpoint, @endpoint) < Point.euc_distance(_dubious_friend.endpoint, @endpoint)
    end
  
  end

end
