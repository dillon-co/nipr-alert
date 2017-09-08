class CreateStatesAgentAppointeds < ActiveRecord::Migration[5.0]
  def change
    create_table :states_agent_appointeds do |t|
      t.string :npn, null: false, default: 0
      t.references :salesman, foreign_key: true
      t.text :appointed_state
      t.string :AK
      t.string :AL
      t.string :AR
      t.string :AZ
      t.string :CA
      t.string :CO
      t.string :CT
      t.string :DC
      t.string :DE
      t.string :FL
      t.string :GA
      t.string :HI
      t.string :IA
      t.string :IDH
      t.string :IL
      t.string :IN
      t.string :KS
      t.string :KY
      t.string :LA
      t.string :MA
      t.string :ME
      t.string :MD
      t.string :MI
      t.string :MN
      t.string :MS
      t.string :MO
      t.string :MT
      t.string :NB
      t.string :NC
      t.string :ND
      t.string :NE
      t.string :NH
      t.string :NJ
      t.string :NM
      t.string :NV
      t.string :NY
      t.string :OH
      t.string :OK
      t.string :ON
      t.string :OR
      t.string :PA
      t.string :PR
      t.string :RI
      t.string :SC
      t.string :SD
      t.string :TN
      t.string :TX
      t.string :UT
      t.string :VA
      t.string :VT
      t.string :WA
      t.string :WI
      t.string :WV
      t.string :WY
      t.timestamps
    end
  end
end
