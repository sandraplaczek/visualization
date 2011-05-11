#Copyright (c) 2009 Sandra Placzek (sandra@lifewizz.com)
#
#Permission is hereby granted, free of charge, to any person obtaining
#a copy of this software and associated documentation files (the
#"Software"), to deal in the Software without restriction, including
#without limitation the rights to use, copy, modify, merge, publish,
#distribute, sublicense, and/or sell copies of the Software, and to
#permit persons to whom the Software is furnished to do so, subject to
#the following conditions:
#
#The above copyright notice and this permission notice shall be
#included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.#!/usr/bin/ruby

require "graphviz"
require "json"

class PathVisualizer

  def get_transformations _ids, _file = "transformationlist.json"
    @tfs = []
    file = File.new(_file, "r")
    content = file.gets
    array = JSON.parse( content )
    array.each do |tf|
      if tf
        if _ids.include? tf["id"] 
          @tfs << tf
        end
      end
    end
    find_troublemakers array
  end
 
  def get_compounds _file = "compoundlist.json"
    @compounds = []
    file = File.new(_file, "r")
    content = file.gets
    array = JSON.parse( content )
    array.each do |cmp|
      if cmp
        @compounds[cmp["id"]] = cmp["label"]
      end
    end
  end

  def find_troublemakers _array
    troublemakers = {}
    _array.each do |tf|
      if tf
        tf["stoichiometry"]["int_compounds"].each do |cmp|
          if troublemakers[cmp[0].to_i]
            troublemakers[cmp[0].to_i] += 1
          else
            troublemakers[cmp[0].to_i] = 1
          end
        end    
      end
    end
    troublemakers = troublemakers.sort {|a,b| b[1] <=> a[1]} 
    @top_troublemakers = []
    troublemakers.each do |tm|
      @top_troublemakers << tm[0]
    end
    @top_troublemakers = @top_troublemakers[0, 10]  
  end

  def draw _path
    g = GraphViz::new("G", "rankdir" => "TB")
    @to_draw = {}
    @tfs.each do |tf|
      name_tf = tf["label"].gsub(/"/, '&quot;').gsub(/>/, '&gt;').gsub(/</, '&lt;')
      g.add_node('"'+name_tf+'"', "shape" => "box", "color" => "black")
      if ext_cmps = tf["stoichiometry"]["ext_compounds"]
        ext_cmps.each do |cmp|
          id = cmp[0].to_i
          unless (@top_troublemakers.include? id)  
            name = @compounds[id]
            g.add_node('"'+name+'"', "shape" => "ellipse")
            if cmp[1].to_f > 0
              g.add_edge('"'+name_tf+'"', '"'+name+'"')
            end
            if cmp[1].to_f < 0
              g.add_edge('"'+name+'"', '"'+name_tf+'"')
            end
          end
        end
      end
      if int_cmps = tf["stoichiometry"]["int_compounds"]
        int_cmps.each do |cmp|
          id = cmp[0].to_i
          unless (@top_troublemakers.include? id)  
            name = @compounds[id]
            g.add_node('"'+name+'"', "shape" => "ellipse") 
            if cmp[1].to_f > 0
              g.add_edge('"'+name_tf+'"', '"'+name+'"')
            end
            if cmp[1].to_f < 0
              g.add_edge('"'+name+'"', '"'+name_tf+'"')
            end
          end
        end
      end 
    end
    g.output( :svg => _path)
  end 
 
  #just while developing
  def return_tfs
    @tfs
  end
  
  def return_cmps
    @compounds
  end
  def return_to_draw
    @to_draw
  end
  def return_troublemakers
    @top_troublemakers
  end  

end
