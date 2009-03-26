require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'classy_files.rb')

# Helpers for pointing at fixture data directories, /notes and /posts,
# found right here underneath the spec dir
module SampleHelpers
  def path_to(dir_name)
    File.expand_path(File.join(File.dirname(__FILE__), dir_name))
  end                                       
    
  def sample_note
    Rush::Dir.new(path_to('notes')).contents.first  
  end
  
  def first_post
    Rush::Dir.new(path_to('posts')).contents.first  
  end
  
  # returns /spec/posts/second_post.rb
  def second_post                                   
    Rush::Dir.new(path_to('posts')).contents[1]
  end
end                          

      
                             
describe "classifying files" do
  include SampleHelpers                      
  include ClassyFiles
  after :each do
    ClassyFiles::Registered.clear
  end                                 

  it "adds #classifications, #classified? methods to Rush::File" do
    first_post.should respond_to(:classifications, :classified?)
  end
    
  it "stores registered classifications globally" do
    # given
    classify_files 'note', :in => path_to('notes')
    classify_files 'post', :in => path_to('posts')
    # then                                     
    ClassyFiles::Registered.should == ['note', 'post']
  end           
  
  it "allows adding methods to files" do
    # given
    classify_files :in => path_to('notes') do
      def intro() lines.first end
    end
    # then
    ClassyFiles::Registered.first.added_methods.should == ['intro']
    sample_note.intro.should == 'hi'
  end
  
  it "dispatches added methods to the correct classification" do
    # given
    classify_files :in => path_to('notes') do
      def intro() lines.first end
    end
    classify_files :in => path_to('posts') do
      def intro() "blah" end
    end
    # then
    sample_note.intro.should == 'hi'
    first_post.intro.should == 'blah'
  end
  
  it "by file extension with the :ext option" do
    # given
    classify_files 'markdown', :ext => 'md' do
      def to_html
        "<html>#{contents}"
      end
    end 
    # then
    first_post.to_html.should match(/<html>/)
    lambda { second_post.to_html }.should raise_error
  end
  
  it ":ext option allows an array of extensions" do
    # given
    classify_files 'markdown', :ext => %w{ a md mdtext markdown rb } do
      def to_html
        "<html>#{contents}"            
      end
    end 
    # then                                           
    first_post.to_html.should match(/<html>/)
    second_post.to_html.should match(/<html>/)
  end        
  
  it "by filname regex matching with the :filename option" do
    # given
    classify_files 'blog_post', :filename => /_post/ do
      def publish!() 200 end
    end 
    # then                   
    post = Rush::Dir.new(path_to('posts'))['second_post.rb']
    post.should be_classified 'blog_post'
    post.publish!.should == 200 
    # and
    not_a_post = Rush::Dir.new(path_to('posts'))['first.md']
    not_a_post.should_not be_classified 'blog_post'
    lambda { not_a_post.publish! }.should raise_error
  end
  
  xit "by declaring it a subclass of another file classification" do
    # given
    classify_files 'post', :in => path_to('posts') do
      def audience() 'anyone' end
    end                  
    
    classify_files 'code:post' , :ext => 'rb' do
      def audience() 'hackers' end
    end        
       
    # then                   
    # second_post.classification.should == "code"
  end
  
  it "return correct classification for a file based on its location" do
    # given
    classify_files 'note', :in => path_to('notes')
    classify_files 'post', :in => path_to('posts')
    # then                                     
    sample_note.classifications.should == ['note']
    first_post.classifications.should == ['post']
  end   

  it "defaults classification name to the unpluralized dir name" do
    # given
    classify_files :in => path_to('notes')
    # then
    sample_note.classifications.should == ['note']        
  end
  
  
  describe "querying for files of a classification in a dir" do 
    before :each do                           
      @notes_dir = Rush::Dir.new(path_to('notes'))  
      classify_files :in => path_to('notes')  
      classify_files 'markdown', :ext => 'md'
    end   
                                        
    after(:each) { ClassyFiles::Registered.clear }

    it "add #files_with_class method to Rush::Dir" do
      @notes_dir.should respond_to(:files_with_class)
    end                           
    
    it "adds #<classification>_files method to Rush::Dir for registered classifications" do
      @notes_dir.should respond_to(:note_files)
      @notes_dir.should_not respond_to(:bogus_files)
    end
      
    it "lets you query for classified files in a dir" do                                  
      @notes_dir.files_with_class('note').should have(2).things
      @notes_dir.note_files.should have(2).things
      
      @notes_dir.files_with_class('markdown').should have(1).thing
      @notes_dir.markdown_files.should have(1).thing      

      lambda { @notes_dir.post_files }.should raise_error
    end
  end                            
end

describe "a file with multiple classifications" do
  include SampleHelpers                      
  include ClassyFiles
  
  before :each do       
    classify_files 'follow_up', :filename => /^(second|2)_/ do
      def face() 'getting back to you' end
    end
                
    classify_files 'code', :ext => '.rb' do
      def face() '010110' end
    end                                          
    
    classify_files 'post', :in => path_to('posts') do
      def face() 'im interesting' end
    end                    
  end  
  
  after :each do
    ClassyFiles::Registered.clear
  end
                                     
  
  describe "dispatches methods to the highest priority classification " do
    xit ":in restrictions have higher priority than :filename and :ext" do                                        
      second_post.face.should == "im interesting"
    end     
    
    xit ":filename restrictions have higher priority than :ext" do
    end                                                          
  end 
end