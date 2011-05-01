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

require 'set'
require 'line'

module GeometricTools  
  class Area
    def initialize _box
      #puts "an area is created"
      @box = _box
      @box.area = self
      @subareas = []
      @lines_to_process = @box.included_lines.keys.clone
      index_lines_to_process_on_x_coord 
  
      while x_coordinates.size > 1
        subarea = crop_leftmost_subarea
        @subareas << subarea
      end
    end
  
    def includes_point? _point
      @subareas.any? do |subarea| 
        is_point_enclosed?(subarea, _point)
      end 
    end
  
    protected
  
    def get_top_and_bottom_line _lines_array
      number_of_lines = _lines_array.size
      raise "unexpected exception" if (number_of_lines < 3 || number_of_lines > 4)
  
      if (number_of_lines == 4)
          _lines_array[0].yI > _lines_array[2].yI ? [_lines_array[0], _lines_array[2]] : [_lines_array[2], _lines_array[0]]
      else
          _lines_array[0].yF > _lines_array[1].yF ? [_lines_array[0], _lines_array[1]] : [_lines_array[1], _lines_array[0]]
      end
    end
  
    def is_point_enclosed? _array, _point 
     x_coord = is_x_coord_enclosed?(_array, _point.x)
     y_coord = is_y_coord_enclosed?(get_top_and_bottom_line(_array), _point)
     ((x_coord==true) && (y_coord==true)) ? true : false
    end
  
    def is_x_coord_enclosed? _array, _x
      (_array[0].xI <= _x) && (_x <= _array[0].xF)
    end
  
    def is_y_coord_enclosed? _array, _point
      _array.any? {|line| line.is_vertical? } ? (_point.y <= _array[0].yF) && (_point.y >= _array[1].yF)  :((_point.y <= _array[0].get_y_for_given_x_on_line(_point.x)) && (_point.y >= _array[1].get_y_for_given_x_on_line(_point.x)))
    end
  
    def index_lines_to_process_on_x_coord
      @lines_by_x_coord = {}
      @lines_to_process.each { |line, value| index_line_on_x line, @lines_by_x_coord }
      @lines_by_x_coord 
    end
  
    # Indexes the passed line (arg 0) in the passed hash (arg 1) having as reference (key) the line's x point(s). The value will be the line itself.
    # The index (hash) contains all lines that have a start/endpoint with a given x coordinate.
    def index_line_on_x _line, _index
      Set.new([_line.startpoint.x, _line.endpoint.x]).each do |x_coord|
        if aligned_lines = _index[x_coord]
          raise("du willst mich verarschen") if aligned_lines.include? _line
          aligned_lines << _line
        else
          _index[x_coord] = [_line]
        end
      end
    end 
  
    def exclude_from_lines_to_process _lines_array
      _lines_array.each do |line_to_exclude|
        raise('unexpected error') unless @lines_to_process.delete(line_to_exclude)
      end
      index_lines_to_process_on_x_coord 
    end
  
    def include_in_lines_to_process *_lines
  
      _lines.each do |line|
        raise('unexpected error') if @lines_to_process.include?(line)
        @lines_to_process << line
      end
      index_lines_to_process_on_x_coord
    end
  
    def close_with_vertical _lines_array
      _lines_array.each {|line| line.adjust!}
      closing_line = Line.new(_lines_array[0].endpoint, _lines_array[-1].endpoint)
      if (following_vertical = find_vertical_that_follows_line(closing_line))
        following_vertical.adjust!
        if following_vertical.yF == closing_line.yI
          merged_line = Line.new(following_vertical.startpoint, closing_line.endpoint)
        elsif following_vertical.yI == closing_line.yF
          merged_line = Line.new(closing_line.startpoint, following_vertical.endpoint)
        elsif following_vertical.yF == closing_line.yF
          merged_line = Line.new(closing_line.startpoint, following_vertical.startpoint)      
        end
        include_in_lines_to_process(merged_line) if merged_line 
        exclude_from_lines_to_process([@following_vertical])
        @following_vertical = nil
      else
        include_in_lines_to_process(closing_line)
      end
      _lines_array << closing_line
    end
    
    def find_vertical_that_follows_line _first_line
      @lines_by_x_coord[_first_line.xI].each do |line|
        if line.is_vertical? 
          @following_vertical = (line==_first_line) ? nil : line
        end
      end
      @following_vertical
    end

    def regularize_cone _line1, _line2, _lines_array
      _lines_array.each do |line| 
        line.adjust! unless line.adjusted?
      end
      line_to_chop = _line1
      (lineA, lineB) = line_to_chop.chop_line_at_given_x(_line2.xF)
      include_in_lines_to_process(lineB)
      new_array_of_lines = _lines_array.collect {|line| ((line == line_to_chop) ? lineA : line) }
      new_array_of_lines
    end
    
    # Returns a polyline, removes from lines_to_process the included members, and reindexes.
    def crop_leftmost_subarea
      return nil if x_coordinates.size < 1
  
      if lines_that_originate_on_x(x_coordinates[0])[0].is_vertical?
        start_line = lines_that_originate_on_x(x_coordinates[0])[1]
      else
        start_line = lines_that_originate_on_x(x_coordinates[0])[0]
      end
  
      convex_space_of_startline = convex_space(start_line)
  
      last_line = convex_space_of_startline[-1]
      exclude_from_lines_to_process convex_space_of_startline
  
      if (last_line.xF == start_line.xF)
        crop = last_line.yF == start_line.yF ? convex_space_of_startline : close_with_vertical(convex_space_of_startline)
      elsif (last_line.xF < start_line.xF)
        new_array_of_lines = regularize_cone(start_line, last_line, convex_space_of_startline)
        crop = close_with_vertical(new_array_of_lines)
      elsif (last_line.xF > start_line.xF)
        new_array_of_lines = regularize_cone(last_line, start_line, convex_space_of_startline)
        crop = close_with_vertical(new_array_of_lines)
      end
      crop
    end
  
    # Returns an array of lines that form a convex space on X
    def convex_space _first_line
      _first_line.adjust! unless _first_line.adjusted?
      raise "cannot start with a vertical line" if _first_line.is_vertical?
      xI = _first_line.xI
      yI = _first_line.yI
      result = [_first_line]    
      @lines_by_x_coord[xI].each do |bounding_candidate|
        bounding_candidate.adjust! unless bounding_candidate.adjusted?
        if bounding_candidate == _first_line
        else
          if bounding_candidate.is_vertical?
            @lines_by_x_coord[xI].each do |next_bounding_candidate|
              next_bounding_candidate.adjust! unless next_bounding_candidate.adjusted?
              if (next_bounding_candidate != _first_line) && (next_bounding_candidate != bounding_candidate)
                result << bounding_candidate << next_bounding_candidate
              end
            end
          elsif (bounding_candidate.yI == yI)
            result << bounding_candidate
          end
        end
      end
      raise("unexpected result size: #{result.size}") if ((result.size < 2) || (result.size > 3))
      result
    end
  
    def lines_that_originate_on_x _x
      lines = []
      @lines_by_x_coord[_x].each { |line| lines << line if line.xF >= _x }
      lines
    end
  
    # Returns an ordered array with the x coordinate of all edges of the box
    def x_coordinates 
      @lines_by_x_coord.keys.sort
    end
  
  end

end
