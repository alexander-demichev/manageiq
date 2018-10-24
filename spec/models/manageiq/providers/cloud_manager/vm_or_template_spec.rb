describe ManageIQ::Providers::CloudManager::VmOrTemplate do
  describe "#all" do
    it "scopes" do
      vm = FactoryGirl.create(:vm_openstack)
      t  = FactoryGirl.create(:template_openstack)
      FactoryGirl.create(:vm_vmware)
      FactoryGirl.create(:template_vmware)

      expect(described_class.all).to match_array([vm, t])
    end
  end

  describe "#all_archived" do
    it "scopes" do
      ems = FactoryGirl.create(:ems_openstack)
      vm = FactoryGirl.create(:vm_openstack)
      t  = FactoryGirl.create(:template_openstack)
      # non archived
      FactoryGirl.create(:vm_openstack, :ext_management_system => ems)
      FactoryGirl.create(:template_openstack, :ext_management_system => ems)
      # non cloud
      FactoryGirl.create(:vm_vmware)
      FactoryGirl.create(:template_vmware)

      expect(described_class.archived).to match_array([vm, t])
    end
  end

  let(:root_tenant) do
    Tenant.seed
  end

  let(:default_tenant) do
    root_tenant
    Tenant.default_tenant
  end

  describe "miq_group" do
    let(:user)         { FactoryGirl.create(:user, :userid => 'user', :miq_groups => [tenant_group]) }
    let(:tenant)       { FactoryGirl.build(:tenant, :parent => default_tenant) }
    let(:tenant_users) { FactoryGirl.create(:miq_user_role, :name => "tenant-users") }
    let(:tenant_group) { FactoryGirl.create(:miq_group, :miq_user_role => tenant_users, :tenant => tenant) }
    let(:cloud_template_1) { FactoryGirl.create(:class => "TemplateCloud") }

    it "finds correct tenant id clause when tenant has source_id" do
      User.current_user = user
      tenant.source_id = 1
      expect(VmOrTemplate.tenant_id_clause(user)).to eql ["vms.template = true AND vms.tenant_id = (?) AND vms.publicly_available = false OR vms.template = true AND vms.publicly_available = true OR vms.template = false AND vms.tenant_id IN (?)", tenant.id, [tenant.id]]
    end

    it "finds correct tenant id clause when tenant doesn't have source_id" do
      User.current_user = user
      expect(VmOrTemplate.tenant_id_clause(user)).to eql ["vms.template = true AND vms.tenant_id IN (?) OR vms.template = true AND vms.publicly_available = true OR vms.template = false AND vms.tenant_id IN (?)", [default_tenant.id, tenant.id], [tenant.id]]
    end
  end
end
