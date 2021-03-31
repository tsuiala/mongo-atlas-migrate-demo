package com.example.enterprisepipelineproddemo.controllers;

import com.example.enterprisepipelineproddemo.persistence.DummyTableRepository;
import com.example.enterprisepipelineproddemo.persistence.entities.DummyTable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class HelloWorldController {

    @Autowired
    DummyTableRepository dummyTableRepository;

    @RequestMapping(value = "/api/helloWorld", method = RequestMethod.GET)
    public String helloWorld() {
        return "Hello world";
    }

    @RequestMapping(value = "/api/repositoryTest", method = RequestMethod.GET)
    public List<DummyTable> repositoryTest() {
        return dummyTableRepository.findAll();
    }
}
