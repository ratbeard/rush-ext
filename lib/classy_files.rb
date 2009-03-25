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
    attr_accessor :name,          
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
    
    def applies_to?(file)             
      @restrictions.keys.inject(true) {|truthy, restrict| 
        truthy && passes_restriction?(file, restrict)
      }
    end
    
    def passes_restriction?(file, restriction_name)             
      case restriction_name                              
      when :in
        Rush::Dir.new(@dir).entries.include?(file)
      when :ext
        File.extname(file.name).delete('.') == @ext.delete('.')
      when :filename
        file.name =~ @restrictions[:filename]
      else
        throw "don't know restriction: #{restriction_name}" 
      end
    end              
    
    def <=>(other)
      (other.kind_of?(String) ?  self.name :  self )  <=>  other
    end           
    
    def priority
      @restriction[:in] && 10 or
      @restriction[:filename]
    end
    
    def to_s()  name  end
    
    def inspect()  to_s  end
    
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
      return super if k.nil? 
      extend(k.methods_mixin) 
      send meth, *args, &blk  
    end
  end
  
  
  class Dir

    # alias :normal_files :files
    # def files(opts={})
    #   opts[:type]
    #   
    #     
    #   end
    # end             
    
    def files_with_class(classification)      
      unless ClassyFiles::Registered.include?(classification)      
        throw "'#{classification}' not in classifications: #{ClassyFiles::Registered.inspect}" 
      end
      
      files.find_all {|file| file.classified?(classification)}
    end  
    
    def method_missing(meth, *args, &blk)
      if (classification = file_class_method(meth))
        files_with_class(classification)
      else
        super
      end
    end      
    
    def respond_to?(meth)
      super or ClassyFiles::Registered.include?(file_class_method(meth))
    end
    
    private
    # Returns the leading name if the given str/sym looks like:
    # file_class_method?('something_files') # => 'something'  
    # else returns nil
    def file_class_method(meth)
      meth.to_s =~ /^(\w+)_files$/; $1
    end    
    
  end  
  
end