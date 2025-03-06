package com.socgen.unibank.services.autotest.gateways.outbound.persistence;

import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.entity.Document;
import com.socgen.unibank.services.autotest.entity.MetaData;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import com.socgen.unibank.services.autotest.repository.DocumentRepositoryJpa;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
@AllArgsConstructor
public class DocumentRepoImpl implements DocumentRepository {

    private final DocumentRepositoryJpa documentRepositoryJpa;

    @Override
    public List<DocumentDTO> findAllDocuments() {
        // Charger toutes les entités Document depuis la base de données
        List<Document> documents = documentRepositoryJpa.findAll();

        // Convertir les entités en DTO pour les retourner
        return documents.stream()
                .map(document -> new DocumentDTO(
                        null, // URN can be set as per your logic
                        document.getName(),
                        document.getDescription(),
                        document.getStatus(),
                        document.getMetadata().stream()
                                .map(metaData -> new MetaDataDTO(metaData.getKey(), metaData.getValue()))
                                .collect(Collectors.toList()),
                        document.getCreationDate(),
                        document.getModificationDate(),
                        null, // Mapping AdminUser can be added according to your requirements
                        null
                ))
                .collect(Collectors.toList());
    }

    @Override
    public void saveDocument(DocumentDTO documentDTO) {
        // Convertir le DTO en une entité et sauvegarder dans la base
        Document document = new Document();

        document.setName(documentDTO.getName());
        document.setDescription(documentDTO.getDescription());
        document.setStatus(documentDTO.getStatus());
        document.setCreationDate(documentDTO.getCreationDate());
        document.setModificationDate(documentDTO.getModificationDate());
        document.setCreatedBy(documentDTO.getCreatedBy().getEmail());  // Assuming AdminUser has an `email` field
        document.setModifiedBy(documentDTO.getModifiedBy().getEmail());

        // Convertir les métadonnées
        List<MetaData> metadataList = documentDTO.getMetadata().stream()
                .map(metadataDTO -> new MetaData(null, document, metadataDTO.getKey(), metadataDTO.getValue()))
                .collect(Collectors.toList());
        document.setMetadata(metadataList);

        documentRepositoryJpa.save(document);
    }
}
