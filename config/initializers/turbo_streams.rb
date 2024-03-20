# frozen_string_literal: true

Turbo::Streams::BroadcastJob.queue_name = :real_time
Turbo::Streams::ActionBroadcastJob.queue_name = :real_time
Turbo::Streams::BroadcastStreamJob.queue_name = :real_time
