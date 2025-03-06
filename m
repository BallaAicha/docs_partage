modifie ici pour qu'il ne mock plus mais il va récupérer les données dans la base ::package com.socgen.unibank.services.autotest.gateways.outbound.persistence;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.platform.domain.URN;
import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import com.socgen.unibank.domain.base.DocumentStatus;

@Component
@AllArgsConstructor
public class DocumentRepoImpl implements DocumentRepository {

    private final List<DocumentDTO> documents = new ArrayList<>();

//    @Override
//    public List<DocumentDTO> findAllDocuments() {
//        List<DocumentDTO> documents = new ArrayList<>();
//        documents.add(new DocumentDTO(
//            new URN(null),
//            "Document 1",
//            "Description of Document 1",
//            DocumentStatus.CREATED,
//            List.of(new MetaDataDTO("key1", "value1")),
//            new Date(),
//            new Date(),
//            new AdminUser("creator1"),
//            new AdminUser("modifier1")
//        ));
//        documents.add(new DocumentDTO(
//            new URN(null),
//            "Document 2",
//            "Description of Document 2",
//            DocumentStatus.CREATED,
//            List.of(new MetaDataDTO("key2", "value2")),
//            new Date(),
//            new Date(),
//            new AdminUser("creator2"),
//            new AdminUser("modifier2")
//        ));
//        return documents;
//    }

    @Override
    public void saveDocument(DocumentDTO document) {
        documents.add(document);
    }


}
