require 'spec_helper'

describe PersonMailer do
  
  before(:all) do
    @test_person, @session = get_test_person_and_session
    @test_person2, @session2 = get_test_person_and_session("kassi_testperson2")
    @test_person2.locale = "en"
    @test_person2.save
  end   

  it "should send email about a new message" do
    @conversation = Factory(:conversation)
    @conversation.participants << @test_person
    @conversation.participants << @test_person2
    @message = Factory(:message)
    @message.conversation = @conversation
    @message.save
    email = PersonMailer.new_message_notification(@message).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [@test_person2.email], email.to unless @test_person2.email.nil? #if running tests with Kassi account that doesn't get emails from ASI
    assert_equal "You have a new message in Kassi", email.subject
  end
  
  it "should send email about a new comment to own listing" do
    @comment = Factory(:comment)
    @test_person.update_attributes({ "given_name" => "Teppo", "family_name" => "Testaaja" }, @session.cookie)
    email = PersonMailer.new_comment_to_own_listing_notification(@comment).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [@test_person.email], email.to unless @test_person2.email.nil? #if running tests with Kassi account that doesn't get emails from ASI
    assert_equal "Teppo Testaaja has commented your listing in Kassi", email.subject
  end
  
  it "should send email about an accepted and rejected offer or request" do
    @conversation = Factory(:conversation)
    @conversation.participants << @test_person
    @conversation.participants << @test_person2
    @test_person.update_attributes({ "given_name" => "Teppo", "family_name" => "Testaaja" }, @session.cookie)
    
    @conversation.update_attribute(:status, "accepted")
    email = PersonMailer.conversation_status_changed(@conversation).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [@test_person2.email], email.to unless @test_person2.email.nil? #if running tests with Kassi account that doesn't get emails from ASI
    assert_equal "Your offer was accepted", email.subject
    
    @conversation.update_attribute(:status, "rejected")
    email = PersonMailer.conversation_status_changed(@conversation).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [@test_person2.email], email.to unless @test_person2.email.nil? #if running tests with Kassi account that doesn't get emails from ASI
    assert_equal "Your offer was rejected", email.subject
  end
  
  it "should send email about a new badge" do
    @badge = Factory(:badge)
    email = PersonMailer.new_badge(@badge).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [@test_person.email], email.to unless @test_person2.email.nil? #if running tests with Kassi account that doesn't get emails from ASI
    assert_equal "You have achieved a badge 'Rookie' in Kassi!", email.subject
  end
  
  it "should send email about a new testimonial" do
    @conversation = Factory(:conversation)
    @conversation.participants << @test_person
    @conversation.participants << @test_person2
    @test_person.update_attributes({ "given_name" => "Teppo", "family_name" => "Testaaja" }, @session.cookie)
    @conversation.update_attribute(:status, "accepted")
    @participation = Participation.find_by_person_id_and_conversation_id(@test_person.id, @conversation.id)
    @testimonial = Testimonial.new(:grade => 0.75, :text => "Yeah", :author_id => @test_person.id, :receiver_id => @test_person2.id, :participation_id => @participation.id)
    email = PersonMailer.new_testimonial(@testimonial).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [@test_person2.email], email.to unless @test_person2.email.nil? #if running tests with Kassi account that doesn't get emails from ASI
    assert_equal "Teppo Testaaja has given you feedback in Kassi", email.subject
  end
  
  it "should remind about testimonial" do
    @conversation = Factory(:conversation)
    @conversation.participants << @test_person
    @conversation.participants << @test_person2
    @test_person.update_attributes({ "given_name" => "Teppo", "family_name" => "Testaaja" }, @session.cookie)
    @conversation.update_attribute(:status, "accepted")
    @participation = Participation.find_by_person_id_and_conversation_id(@test_person2.id, @conversation.id)
    email = PersonMailer.testimonial_reminder(@participation).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [@test_person2.email], email.to unless @test_person2.email.nil? #if running tests with Kassi account that doesn't get emails from ASI
    assert_equal "Reminder: remember to give feedback to Teppo Testaaja", email.subject
  end
  
  it "should send email to admins of new feedback" do
    @feedback = Factory(:feedback)
    email = PersonMailer.new_feedback(@feedback).deliver
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal APP_CONFIG.feedback_mailer_recipients.split(", "), email.to
  end  

end