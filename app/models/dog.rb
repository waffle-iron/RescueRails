#    Copyright 2017 Operation Paws for Homes
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# == Schema Information
#
# Table name: dogs
#
#  id                      :integer          not null, primary key
#  name                    :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  tracking_id             :integer
#  primary_breed_id        :integer
#  secondary_breed_id      :integer
#  status                  :string(255)
#  age                     :string(75)
#  size                    :string(75)
#  is_altered              :boolean
#  gender                  :string(6)
#  is_special_needs        :boolean
#  no_dogs                 :boolean
#  no_cats                 :boolean
#  no_kids                 :boolean
#  description             :text
#  foster_id               :integer
#  adoption_date           :date
#  is_uptodateonshots      :boolean          default(TRUE)
#  intake_dt               :date
#  available_on_dt         :date
#  has_medical_need        :boolean          default(FALSE)
#  is_high_priority        :boolean          default(FALSE)
#  needs_photos            :boolean          default(FALSE)
#  has_behavior_problem    :boolean          default(FALSE)
#  needs_foster            :boolean          default(FALSE)
#  petfinder_ad_url        :string(255)
#  adoptapet_ad_url        :string(255)
#  craigslist_ad_url       :string(255)
#  youtube_video_url       :string(255)
#  first_shots             :string(255)
#  second_shots            :string(255)
#  third_shots             :string(255)
#  rabies                  :string(255)
#  vac_4dx                 :string(255)
#  bordetella              :string(255)
#  microchip               :string(255)
#  original_name           :string(255)
#  fee                     :integer
#  coordinator_id          :integer
#  sponsored_by            :string(255)
#  shelter_id              :integer
#  medical_summary         :text
#  heartworm_preventative  :string
#  flea_tick_preventative  :string
#  medical_review_complete :boolean          default(FALSE)
#

class Dog < ApplicationRecord
  include Auditable

  attr_accessor :primary_breed_name, :secondary_breed_name

  belongs_to :primary_breed, class_name: 'Breed'
  belongs_to :secondary_breed, class_name: 'Breed'
  belongs_to :foster, class_name: "User"
  belongs_to :coordinator, class_name: "User"
  belongs_to :shelter

  has_many :comments, -> { order 'created_at DESC' }, as: :commentable
  has_many :attachments, as: :attachable, dependent: :destroy
  has_many :photos, -> { order 'position ASC' }, dependent: :destroy
  has_many :adoptions, dependent: :destroy
  has_many :adopters, through: :adoptions

  accepts_nested_attributes_for :attachments, allow_destroy: true
  accepts_nested_attributes_for :photos, allow_destroy: true

  validates :name, presence: true,
           length: { maximum: 75 },
           uniqueness: { case_sensitive: false }

  validates :tracking_id, uniqueness: true, presence: true

  STATUSES = ['adoptable', 'adopted', 'adoption pending',
        'on hold', 'not available', 'return pending', 'coming soon','completed']
  validates_inclusion_of :status, in: STATUSES
  validates_presence_of :status

  PETFINDER_STATUS =
  {
    "adoptable" => "A",
    "adoption pending" => "P",
    "on hold" => "H",
    "return pending" => "H",
    "coming soon" => "H"
  }.freeze

  PETFINDER_SIZE =
  {
    "small" => "S",
    "medium" => "M",
    "large" => "L",
    "extra large" => "XL"
  }.freeze

  PETFINDER_GENDER =
  {
    "Male" => "M",
    "Female" => "F"
  }

  AGES = ['baby', 'young', 'adult', 'senior']
  validates_inclusion_of :age, in: AGES, allow_blank: true

  SIZES = ['small', 'medium', 'large', 'extra large']
  validates_inclusion_of :size, in: SIZES, allow_blank: true

  GENDERS = ['Male', 'Female']
  validates_inclusion_of :gender, in: GENDERS, allow_blank: true

  before_save :update_adoption_date

  def attributes_to_audit
    %w(status)
  end

  def to_petfinder_status
    PETFINDER_STATUS[status]
  end

  def to_petfinder_size
    PETFINDER_SIZE[size]
  end

  def to_petfinder_gender
    PETFINDER_GENDER[gender]
  end

  def update_adoption_date
    return unless status_changed?
    return unless status != 'completed'

    self.adoption_date = nil
    self.adoption_date = Date.today() if adopted?
  end

  def adopted?
    status == 'adopted'
  end

  def self.next_tracking_id
    connection.select_value("SELECT nextval('tracking_id_seq')")
  end
end
