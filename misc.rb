# orig
Classify::classify_file_as 'note', :in => 'notes/'
                                                                
# lame "fluent interface":
classify_files_in('notes/').as('note').if do |file|
  file.name =~ /_spec/
end                                               

file_classifications('note').subclassify('video').when do |file|  
end

                          
# bingo!
classify_files 'note', :in => 'notes/'
classify_files 'markdown', :filename => /\.md$/
classify_files 'video', :if => lambda {|file| file =~ /^ø/}

# default classification name as unpluralized form of dir:
classify_files :in => 'notes/'
                         
# add methods:                              
classify_files :in => 'notes/' do   
  def title() name.upcase end
end

# subclassify:
classify_files 'video', :subclass_of => 'note', :filename => /^ø/ do
  def run_time() 
    '43 minutes'
  end    
  def title() 
    'video' + super.title 
  end
end



