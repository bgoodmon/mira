require 'spec_helper'

describe BatchTemplateUpdate do
  subject { FactoryGirl.build(:batch_template_update) }

  it "requires a template_id" do
    subject.template_id = nil
    expect(subject.valid?).to be_false
  end

  it "requires the template to actually change something" do
    template = FactoryGirl.create(:tufts_template, title: nil)
    expect(template.attributes_to_update).to be_empty
    batch = FactoryGirl.build(:batch_template_update, template_id: template.id)
    expect(batch.valid?).to be_false
  end

  it "requires pids" do
    subject.pids = nil
    expect(subject.valid?).to be_false
  end

  it "knows if it's ready to run" do
    expect(BatchTemplateUpdate.new.ready?).to be_false
    expect(subject.ready?).to be_true
  end

  it 'starts processing' do
    template = TuftsTemplate.find(subject.template_id)
    allow(TuftsTemplate).to receive(:find).with(template.id) { template }
    expect(template).to receive(:queue_jobs_to_apply_template).with(subject.creator.id, subject.pids)
    subject.run
    template.delete
  end

  it "only runs when it's ready" do
    b = BatchTemplateUpdate.new
    expect(b.run).to be_false
  end

  it "saves successfully (ensures that :pids gets serialized)" do
    subject.save!
  end
end