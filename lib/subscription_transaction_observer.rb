# use this observer to send out email notifications when transactions are saved
# unclutters the models and ensures users get notified whenever their credit card is accessed
# tracks warning levels so the same message isnt duplicated,.
# Install in environment.rb config.active_record.observers = :subscription_transaction_observer

class SubscriptionTransactionObserver < ActiveRecord::Observer
  observe :subscription_transaction
  
  def after_save(transaction)
    sub = transaction.subscription
    send_mail = sub && sub.subscriber && !sub.subscriber.email.blank?
    case transaction.action
    when 'charge'
      if transaction.success?
        SubscriptionConfig.mailer.deliver_charge_success(sub, transaction) if send_mail
      else 
        sub.increment!(:warning_level)
        case sub.warning_level
        when 1
          SubscriptionConfig.mailer.deliver_charge_failure(sub, transaction) if send_mail
        when 2
          SubscriptionConfig.mailer.deliver_second_charge_failure(sub, transaction) if send_mail
        else
          # expired: do in the app whatever it means to become expired
          # send no mail here
        end
      end
      
    when 'credit', 'refund'
      if transaction.success?
        SubscriptionConfig.mailer.deliver_credit_success(sub, transaction) if send_mail
      end
      # else no email
      
    else # 'validate', 'store', 'update', 'unstore'
      # send no email
    end
  end
  
end
