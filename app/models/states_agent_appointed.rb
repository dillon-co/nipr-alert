# == Schema Information
#
# Table name: states_agent_appointeds
#
#  id              :integer          not null, primary key
#  npn             :string(255)      default("0"), not null
#  salesman_id     :integer
#  appointed_state :text(65535)
#  AK              :string(255)
#  AL              :string(255)
#  AR              :string(255)
#  AZ              :string(255)
#  CA              :string(255)
#  CO              :string(255)
#  CT              :string(255)
#  DC              :string(255)
#  DE              :string(255)
#  FL              :string(255)
#  GA              :string(255)
#  HI              :string(255)
#  IA              :string(255)
#  IDH             :string(255)
#  IL              :string(255)
#  IN              :string(255)
#  KS              :string(255)
#  KY              :string(255)
#  LA              :string(255)
#  MA              :string(255)
#  ME              :string(255)
#  MD              :string(255)
#  MI              :string(255)
#  MN              :string(255)
#  MS              :string(255)
#  MO              :string(255)
#  MT              :string(255)
#  NB              :string(255)
#  NC              :string(255)
#  ND              :string(255)
#  NE              :string(255)
#  NH              :string(255)
#  NJ              :string(255)
#  NM              :string(255)
#  NV              :string(255)
#  NY              :string(255)
#  OH              :string(255)
#  OK              :string(255)
#  ON              :string(255)
#  OR              :string(255)
#  PA              :string(255)
#  PR              :string(255)
#  RI              :string(255)
#  SC              :string(255)
#  SD              :string(255)
#  TN              :string(255)
#  TX              :string(255)
#  UT              :string(255)
#  VA              :string(255)
#  VT              :string(255)
#  WA              :string(255)
#  WI              :string(255)
#  WV              :string(255)
#  WY              :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class StatesAgentAppointed < ApplicationRecord
  
end
