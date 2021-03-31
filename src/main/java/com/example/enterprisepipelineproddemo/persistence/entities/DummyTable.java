package com.example.enterprisepipelineproddemo.persistence.entities;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;

@Entity
public class DummyTable {

    @Id
    @GeneratedValue
    private int id;

    private String dummy;
}
