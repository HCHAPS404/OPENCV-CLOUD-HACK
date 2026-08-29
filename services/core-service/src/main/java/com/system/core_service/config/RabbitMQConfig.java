package com.system.core_service.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String EXCHANGE_NAME = "krop.exchange";
    public static final String OPTICAL_QUEUE = "optical_processing_queue";
    public static final String ROUTING_KEY_OPTICAL = "krop.optical.#";

    @Bean
    public Queue opticalQueue() {
        // durable = true para que no se borre si RabbitMQ se reinicia
        return new Queue(OPTICAL_QUEUE, true);
    }

    @Bean
    public TopicExchange kropExchange() {
        return new TopicExchange(EXCHANGE_NAME);
    }

    @Bean
    public Binding bindingOptical(Queue opticalQueue, TopicExchange kropExchange) {
        return BindingBuilder.bind(opticalQueue).to(kropExchange).with(ROUTING_KEY_OPTICAL);
    }
}