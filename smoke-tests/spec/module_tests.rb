require "spec_helper"

describe "apply and delete all modules" do
  namespace = "apply-modules-#{readable_timestamp}"

  before(:all) do
    create_namespace(namespace)
  end

  after(:all) do
    delete_namespace(namespace)
  end

  context "terraform apply resources" do
    it "fails http get" do
      cd smoketests/fixtures/resources/
      terraform apply

    end
  end

  context "terraform destroy" do
    it "destroys terraform resources" do
      cd smoketests/fixtures/resources/
      terraform destroy
    end
  end
end
