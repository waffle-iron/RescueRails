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

class MailChimpClient
  attr_reader :gibbon

  def initialize
    @gibbon = Gibbon::Request.new(debug: true)
    @gibbon.timeout = 30
  end

  def subscribe(list_id, email, merge_vars, interests)
    gibbon.lists(list_id).members(hashed(email)).upsert(
      body: {
        email_address: email,
        status_if_new: 'pending',
        merge_fields: merge_vars,
        interests: {
          interest_active_application => interests.fetch(:active_application, false),
          interest_adopted_from_oph => interests.fetch(:adopted_from_oph, false)
        }
      }
    )
  end

  def unsubscribe(list_id, email)
    gibbon
      .lists(list_id)
      .members(hashed(email))
      .update(body: { status: 'unsubscribed' })
  end

  def user_subscribe(name, email)
    merge_vars = {
      'FNAME' => name
    }

    gibbon.lists(user_list_id).members(hashed(email)).upsert(
      body: {
        email_address: email,
        status_if_new: 'pending',
        merge_fields: merge_vars,
      }
    )
  end

  def user_unsubscribe(email)
    unsubscribe(user_list_id, email)
  end

  def adopter_subscribe(email, merge_vars, interests)
    subscribe(adopter_list_id, email, merge_vars, interests)
  end

  def adopter_unsubscribe(email)
    unsubscribe(adopter_list_id, email)
  end

  private

  def hashed(email)
    Digest::MD5.hexdigest(email.downcase)
  end

  def config(key)
    Rails.application.config_for(:mailchimp)
         .with_indifferent_access[key]
  end

  def user_list_id
    config(:user_list_id)
  end

  def adopter_list_id
    config(:adopter_list_id)
  end

  def interest_active_application
    config(:interest_active_application)
  end

  def interest_supporter
    config(:interest_supporter)
  end

  def interest_adopted_from_oph
    config(:interest_adopted_from_oph)
  end
end
