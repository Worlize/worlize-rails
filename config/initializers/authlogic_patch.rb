# IMPORTANT... we have to patch authlogic to never perform LIKE
# queries based on the value of the "case_sensitive" option in the
# validate_uniqueness_of_login_field_options hash.  MySQL performs
# a case insensitive search by default anyway, and the use of the
# LIKE query returns wrong results since we also used to allow
# spaces in the username, before migrating to having a separate
# login name field.

module Authlogic
  module ActsAsAuthentic
    module Login
      module Config
        def find_by_smart_case_login_field(login)
          find_with_case(login_field, login, true)
        end
      end
    end
  end
end

