require 'rails_helper'

describe Doorkeeper::OpenidConnect::CodeIdToken do
  subject { described_class.new(access_token, nonce, auth_code) }
  let(:access_token) { create :access_token, resource_owner_id: user.id, scopes: 'openid' }
  let(:user) { create :user }
  let(:nonce) { '123456' }
  let(:application) do
    scopes = double(all: ['openid'])
    double(:application, id: 9990, scopes: scopes)
  end
  let(:pre_auth) do
    double(
        :pre_auth,
        client: application,
        redirect_uri: 'http://tst.com/cb',
        state: nil,
        scopes: Doorkeeper::OAuth::Scopes.from_string('openid'),
        error: nil,
        authorizable?: true,
        nonce: '12345'
    )
  end
  let(:auth_code) do
    Doorkeeper::OAuth::Authorization::Code.new(pre_auth, double(id: 1)).tap do |c|
      c.issue_token
    end
  end


  before do
    allow(Time).to receive(:now) { Time.at 60 }
  end

  describe '#claims' do
    it 'returns all default claims with c_hash' do
      # token of access_grant is from http://openid.net/specs/openid-connect-core-1_0.html
      # so we can test `c_hash` value
      auth_code.token.update(token: 'jHkWEdUXMU1BwAsC4vtUsZwnNvTIxEl0z9K3vx5KF0Y')
      expect(subject.claims).to eq({
         iss: 'dummy',
         sub: user.id.to_s,
         aud: access_token.application.uid,
         exp: 180,
         iat: 60,
         nonce: nonce,
         auth_time: 23,
         both_responses: 'both',
         id_token_response: 'id_token',
         c_hash: "77QmUPtjPfzWtF2AnpK9RQ",
       })
    end
  end
end
