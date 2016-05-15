class Response < ActiveRecord::Base
  def self.fetch_data
    url = 'https://api.typeform.com/v1/form/agfRBf?key=a3dcef6a6c673b888259ce86e24985cbebeabfd5&completed=true&order_by[]=date_submit,desc&limit=1'
    response = RestClient.get(url)
    data = JSON.parse(response)

    data['responses'].each do |response|
      token = response['token']
      new_response = ::Response.find_or_initialize_by(token: token)

      unless new_response.persisted?
        new_response.save
        self.create_github_commit(response)
      end
    end; nil
  end

  def self.create_github_commit(response)
    github = Octokit::Client.new(login: 'hapiben', password: 'Q1W2e3r4')
    repo = 'taxikick/taxikick.github.io'
    ref = 'heads/master'
    sha_latest_commit = github.ref(repo, ref).object.sha
    sha_base_tree = github.commit(repo, sha_latest_commit).commit.tree.sha
    content = self.build_content(response)

    file_name = File.join('_posts', "#{Date.today.strftime('%Y-%m-%d')}-#{response['token']}-#{rand(999)}.md")
    blob_sha = github.create_blob(repo, content)

    sha_new_tree = github.create_tree(repo, 
                     [ { :path => file_name, 
                         :mode => '100644', 
                         :type => 'blob', 
                         :sha => blob_sha } ], 
                     {:base_tree => sha_base_tree }).sha

    commit_message = "New taxikick report - #{response['token']}"
    sha_new_commit = github.create_commit(repo, commit_message, sha_new_tree, sha_latest_commit).sha
    updated_ref = github.update_ref(repo, ref, sha_new_commit)
  end

  def self.build_violations(answers)
    violations = answers.map { |key, value|
      if key =~ /list_/
        value
      else
        ''
      end
    }.compact.reject(&''.method(:==))

    return violations.take(2).join(', ')
  end

  def self.build_title(plate_number, location)
    content = plate_number

    content += " - #{location}" if location
    content
  end

  def self.build_content(response)
    answers = response['answers']
    plate_number = answers['textfield_20802169'].upcase.delete(' ')
    taxi_name = answers['textfield_20802266']
    location = answers['textfield_20802329']
    incident_date = answers['date_20802506']
    comments = answers['textarea_20802709']
    name = answers['textfield_20802185']
    email = answers['email_20802171']
    contact_details = answers['textfield_20802876']
    violations = self.build_violations(answers)

    post_title = self.build_title(plate_number, location)
    taxi_name = "Name of taxi: #{taxi_name}" if taxi_name
    taxi_name = "Name of taxi: Unknown" unless taxi_name
    content = 
"---
layout: post
title: #{post_title}
---

### #{taxi_name}

#{comments}

```#{violations}```
"
  end
end


