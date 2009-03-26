`FileClassification` provides a way to extend `Rush::Files` at a finer granularity than using the `~/.rush/commands` file, which applies the methods to all files.  With `FileClassifications` you can classify files based on their filename, extension, what directory glob they're under, or any arbitrary characteristic of the file.  

When a missing method is called on a `Rush::File`, we find any declared classifications that apply to the file w/ that method and mix them in.  

I wrote this because I wanted a `title` method to behave differently based on whether a file was a "note" file or a "blog post" file, so I over-engineered and wrote this extension to add polymorphic behavior to files in Rush.

For example, all markdown files will get a handy helper from this:

    classify_files 'markdown', :ext => %w{ md mdtext markdown } do
      def to_html
        require 'maruku'
        Maruku.new(contents).to_html
      end
    end                  
    
Now you can do:

    Rush['~/notes'].markdown_files.to_html

    
Declaration Syntax:

    classify_files 'note', :in => 'notes/'
    classify_files 'markdown', :ext => 'md'
    classify_files 'video', :filename => /^ø/  

    # default classification name as unpluralized form of dir:
    classify_files :in => 'notes/'
                         
    # add methods:                              
    classify_files :in => 'notes/' do   
      def title() name.upcase end
    end

# TODO:

method dispatch priority (some specs written)       

apply to Entries and mix in to Array, so this actually works:

    Rush['~/notes'].markdown_files.to_html 

arbitrary restriction:

    classify_files 'large', :if => lambda {|file| file.size > 1.mb}

subclassify:

    classify_files 'video:note', :filename => /^ø/ do
      def run_time 
        '43 minutes'
      end      
  
      def title 
        'video - ' + super.title 
      end
    end