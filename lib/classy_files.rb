require 'rubygems'
require 'rush'                                            

module ClassyFiles 

  # register a new file classification:
  def classify_files(*args, &method_def_block)
    Registered << FileClassification.new(*args, &method_def_block)
  end
  
                           
  # Global file classification registrar
  Registered = []
  def Registered.for(file)
    matches = find_all {|kind| kind.applies_to?(file) }
  end
                    
  
  # Encapsulate a classification.
  # name, conditions, and methods to add
  # == to its name, FileClassification.new('foo') == 'foo'
  class FileClassification 
    include Comparable           
    attr_accessor :name,          
                  :methods_mixin,
                  :restrict    # [:in, :ext, :filename]

    # hash of procs that take in a file and a value, and see if the file
    # passes the restriction, based on the value given at declaration time
    # See applies_to? method
    @@restriction_procs = {
      :in => proc {|file, path| Rush::Dir.new(path).entries.include?(file) },
      :ext => proc {|file, extensions| 
        extensions = [extensions] unless extensions.kind_of?(Array)
        extensions.inject(false) {|falsey, ext|
          falsey || File.extname(file.name).delete('.') == ext.delete('.')
        }
      },
      :filename => proc {|file, regex| file.name =~ regex }
    }
    
    def initialize(*args, &methods_def_block)           
      @restrict = args.pop
      @name = args.first || generate_name
      @methods_mixin = Module.new(&methods_def_block)
    end 
    
    # Returns if this classification applies to the given file
    def applies_to?(file)                                          
      @restrict.inject(true) {|truthy, (restriction, value)| 
        truthy && @@restriction_procs[restriction].call(file, value)
      }
    end
    
    def added_methods
      @methods_mixin.instance_methods      
    end                                                

    # Equivelant to a string of this classications names
    def <=>(other)
      (other.kind_of?(String) ?  self.name :  self )  <=>  other
    end           
    
    def to_s()  name  end
    
    def inspect()  to_s  end
      
    private                                              
    def generate_name                                            
      throw "can't generate name unless :in option given" unless @restrict[:in]
      @restrict[:in].to_s.split('/').last.chomp('s')      
    end
  end
end


module Rush
  class File
    def classifications
      ClassyFiles::Registered.for(self)
    end
    
    def classified?(name=nil)
      name ?  classifications.include?(name) :  !classifications.empty?
    end                          

    # Find first classification that adds the called method and 
    # mix it in to self and call the method
    def method_missing(meth, *args, &blk)
      classify = classifications.find {|kind| kind.added_methods.include?(meth.to_s)}
      return super if classify.nil? 
      self.extend(classify.methods_mixin) 
      self.send(meth, *args, &blk)
    end
  end
  
  
  class Dir    
    def files_with_class(classification)      
      unless registered?(classification)
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
      super or registered?(file_class_method(meth))
    end
    
    private
    # Returns the leading name if the given str/sym looks like:
    # file_class_method?('something_files') # => 'something'  
    # else returns nil
    def file_class_method(meth)
      meth.to_s =~ /^(\w+)_files$/; $1
    end    
    
    # Returns if the given classification is registered.
    def registered?(classification, opts={})             
      registered = ClassyFiles::Registered.include?(classification)
    end
  end  
  
end