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

require 'area'

module GeometricTools
  
  class Box
    attr_accessor :included_lines, :area
  
    @@boxes = []
  
    def initialize _line0
      @@boxes << self
      @included_lines = {_line0 => true}
      @included_compounds = []
      @area = nil
    end
  
    def self.filled_boxes
      @@boxes.find_all { |box| box.included_lines.size != 0 }
    end
  
    def self.all_boxes
      @@boxes
    end
  
    def self.reset
      @@boxes = []
    end
  
    def self.filled_boxes_to_svg
      filled_boxes.each do |box|
        box.to_svg
      end
    end
  
    def included_compounds
    @included_compounds
    end
  
    def delete_double_lines
      @included_lines.each do |line1, value|
        if ((line1.xI == line1.xF) && (line1.yI == line1.yF)) 
          @included_lines.delete(line1) 
        end
      end
    end
  
  
    # flips the box over letting all the lines fall, it is shaken so much that the box gets trashed... no more line in, sorry
    def drop_lines
      lines_to_dump = @included_lines.keys
      @included_lines = {}
      lines_to_dump
    end
  
    def has_line? _line
      @included_lines.include? _line
    end
  
    def << _new_line
     raise "line is already in box" if @included_lines.has_key? _new_line
     raise 'box was probably already emptied' if @included_lines.size == 0
     @included_lines[_new_line] = true 
    end
    
    def to_svg
      name="box"+@@boxes.index(self).to_s
      beginning name
      @doc.root.add_element("g", {"stroke-width" => "1", "stroke" => "rgb(0,255,0)"})
      self.included_lines.each do |line|
          x1= line[0].startpoint.x
          y1= line[0].startpoint.y
          x2= line[0].endpoint.x
          y2= line[0].endpoint.y
          @doc.root.elements[1].add_element("line", {"x1" => x1, "y1" => y1, "x2" => x2, "y2" => y2})
      end
      save name
    end
    
    def close_box!
      unhappy_lines = []
      self.included_lines.each do |line, value|
        unless line.has_line_two_friends?
          unhappy_lines << line
        end
      end
      unhappy_lines[0].close_gap_to_line unhappy_lines[1] if unhappy_lines.size ==2
    end
    
    def store_point_in_box _point
      if includes_point?(_point)
        included_compounds << _point
      end
    end
   
    def includes_point? _point
      self.close_box!    
      @area ||= Area.new self
      unless @area.includes_point? _point
        is_point_enclosed_in_circle? _point
      end
      @area.includes_point?(_point) ? true : false
    end
    
    def is_point_enclosed_in_circle? _point
      readout_svg
      @circles.any? do |circle|
        center = Point.new(circle[0], circle[1])
        Point.euc_distance(_point, center)<=circle[2] ? circle : nil
      end
    end
  end

end
