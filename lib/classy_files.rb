require 'rush'                                            

module ClassyFiles 

  # register new file classifications 
  def classify_files(*args, &method_def_block)
    Registered << FileKind.new(*args, &method_def_block)
  end
                           
  # Global file classification registrar
  Registered = []
  def Registered.for(file)
    matches = find_all {|kind| kind.applies_to?(file) }
  end
  
  # Encapsulate a classification.
  # name, conditions, and methods to add
  # == to its name, FileKind.new('foo') == 'foo'
  class FileKind 
    include Comparable
    attr_accessor :name,          # 
                  :methods_mixin, # Module to mixin in to file obj 
                  :restrictions   # :in, :ext, :filename
    
    @@valid_restrictions = [:in, :ext, :filename]

    def parse_opts(opts)            
        restrictions = {}
        @@valid_restrictions.each do |k|
          v = opts.delete(k)
          restrictions[k] = v if v
        end
        return restrictions, opts
    end
    
    def initialize(*args, &methods_def_block)           
      @restrictions, @opts = parse_opts(args.pop)                          
      opts = @restrictions
      @dir = opts[:in]
      @ext = opts[:ext]  
      @name = args.first || generate_name
      @methods_mixin = Module.new(&methods_def_block)
    end                                                 
                                            
    def generate_name
      throw "can't generate name unless :in option given" if @dir.nil?
      @dir.to_s.split('/').last.chomp('s')      
    end
    
    def rush_dir
      Rush::Dir.new(@dir) 
    end
    
    def applies_to?(file)
      if @restrictions[:in]
        return rush_dir.entries.include?(file)
      end
      if @restrictions[:ext]
        return File.extname(file.name)[1..-1] == @ext
      end                
      if @restrictions[:filename]
        return file.name =~ @restrictions[:filename]
      end
    end
    
    def <=>(other)
      if other.kind_of? String
        self.name <=> other
      else
        self <=> other
      end
    end           
    
    def to_s 
      name
    end
    
    def inspect
      to_s
    end
    
    def added_methods
      @methods_mixin.instance_methods      
    end
    
    def adds_method?(meth)
      added_methods.include?(meth.to_s)
    end
  end
end


module Rush
  class File
    def classifications
      ClassyFiles::Registered.for(self)
    end
    
    def classified?(name)
      classifications.include? name
    end                          

    # Find first classification that adds the called method and 
    # mix it in to self and call the method
    def method_missing(meth, *args, &blk)
      k = classifications.find {|kind| kind.adds_method?(meth)}
      if k.nil? 
        super
      else
        self.extend(k.methods_mixin) 
        self.send meth, *args, &blk
      end
    end
  end
end