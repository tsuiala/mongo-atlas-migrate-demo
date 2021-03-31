package com.example.enterprisepipelineproddemo.persistence;

import com.example.enterprisepipelineproddemo.persistence.entities.DummyTable;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DummyTableRepository extends CrudRepository<DummyTable, Integer> {

    List<DummyTable> findAll();
}
