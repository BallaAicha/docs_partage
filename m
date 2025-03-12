Donne maintenant la logique de création d'un Document ::
Corrige le ::
package com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa;
import com.socgen.unibank.platform.domain.URN;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.socgen.unibank.domain.base.DocumentStatus;
import java.util.Date;
import java.util.List;

@Entity
@Table(name = "document")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DocumentStatus status;

    @ManyToOne
    @JoinColumn(name = "folder_id")
    private FolderEntity folder;

    @OneToMany(mappedBy = "document", cascade = CascadeType.ALL)
    private List<DocumentVersionEntity> versions;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "creation_date", nullable = false)
    private Date creationDate;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "modification_date", nullable = false)
    private Date modificationDate;

    @Column(nullable = false)
    private String createdBy;

    @Column(nullable = false)
    private String modifiedBy;

}


package com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa;

import org.springframework.data.jpa.repository.JpaRepository;

public interface DocumentjpaRepo extends JpaRepository<DocumentEntity, Long> {

}



//package com.socgen.unibank.services.autotest.core.usecases;
//
//import com.socgen.unibank.domain.base.AdminUser;
//import com.socgen.unibank.platform.models.RequestContext;
//import com.socgen.unibank.services.autotest.core.DocumentRepository;
//import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
//import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
//import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
//import com.socgen.unibank.services.autotest.model.usecases.CreateDocument;
//import org.springframework.stereotype.Service;
//import com.socgen.unibank.domain.base.DocumentStatus;
//import java.util.Date;
//import java.util.stream.Collectors;
//
//@Service
//public class CreateDocumentImpl implements CreateDocument {
//
//    private final DocumentRepository documentRepository;
//
//    public CreateDocumentImpl(DocumentRepository documentRepository) {
//        this.documentRepository = documentRepository;
//    }
//
//    @Override
//    public DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context) {
//        DocumentDTO newDocument = new DocumentDTO();
//        newDocument.setName(input.getName());
//        newDocument.setDescription(input.getDescription());
//        newDocument.setStatus(DocumentStatus.CREATED);
//        newDocument.setMetadata(input.getMetadata().entrySet().stream()
//            .map(entry -> new MetaDataDTO(entry.getKey(), entry.getValue()))
//            .collect(Collectors.toList()));
//        newDocument.setCreationDate(new Date());
//        newDocument.setModificationDate(new Date());
//        newDocument.setCreatedBy(new AdminUser("usmane@socgen.com"));
//        newDocument.setModifiedBy(new AdminUser("usmane@socgen.com"));
//
//        documentRepository.saveDocument(newDocument);
//        return newDocument;
//    }
//}

package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.domain.base.DocumentStatus;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.platform.service.s3.ObjectStorageClient;
import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.EntityToDTOConverter;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import com.socgen.unibank.services.autotest.model.usecases.CreateDocument;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.Date;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CreateDocumentImpl implements CreateDocument {

    private final DocumentRepository documentRepository;
    private final FolderRepository folderRepository;
  

    public CreateDocumentImpl(DocumentRepository documentRepository, FolderRepository folderRepository) {
        this.documentRepository = documentRepository;
        this.folderRepository = folderRepository;
  
    }



    @Override
    public DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context) {
        return null;
    }
}




package com.socgen.unibank.services.autotest.model.model;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateDocumentEntryRequest {
    private String name;
    private String description;
    private Long folderId;



}



package com.socgen.unibank.services.autotest.model.usecases;
import com.socgen.unibank.platform.domain.Command;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
public interface CreateDocument   {
    DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context);

}


met à jour ici avec la nouvelle logique :
//package com.socgen.unibank.services.autotest.gateways.outbound.persistence;
//
//import com.socgen.unibank.domain.base.AdminUser;
//import com.socgen.unibank.platform.domain.URN;
//import com.socgen.unibank.services.autotest.core.DocumentRepository;
//import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
//import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
//import lombok.AllArgsConstructor;
//import org.springframework.stereotype.Component;
//
//import java.util.ArrayList;
//import java.util.Date;
//import java.util.List;
//
//import com.socgen.unibank.domain.base.DocumentStatus;
//
//@Component
//@AllArgsConstructor
//public class DocumentRepoImpl implements DocumentRepository {
//
//    private final List<DocumentDTO> documents = new ArrayList<>();
//
////    @Override
////    public List<DocumentDTO> findAllDocuments() {
////        List<DocumentDTO> documents = new ArrayList<>();
////        documents.add(new DocumentDTO(
////            new URN(null),
////            "Document 1",
////            "Description of Document 1",
////            DocumentStatus.CREATED,
////            List.of(new MetaDataDTO("key1", "value1")),
////            new Date(),
////            new Date(),
////            new AdminUser("creator1"),
////            new AdminUser("modifier1")
////        ));
////        documents.add(new DocumentDTO(
////            new URN(null),
////            "Document 2",
////            "Description of Document 2",
////            DocumentStatus.CREATED,
////            List.of(new MetaDataDTO("key2", "value2")),
////            new Date(),
////            new Date(),
////            new AdminUser("creator2"),
////            new AdminUser("modifier2")
////        ));
////        return documents;
////    }
//
//    @Override
//    public void saveDocument(DocumentDTO document) {
//        documents.add(document);
//    }
//
//
//}

//package com.socgen.unibank.services.autotest.gateways.outbound.persistence;
//
//import com.socgen.unibank.services.autotest.core.DocumentRepository;
//
//import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.DocumentEntity;
//import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.DocumentjpaRepo;
//import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.MetaDataEntity;
//import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
//import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
//
//import lombok.AllArgsConstructor;
//import org.springframework.stereotype.Component;
//
//import java.util.List;
//import java.util.stream.Collectors;
//
//@Component
//@AllArgsConstructor
//public class DocumentRepoImpl implements DocumentRepository {
//
//    private final DocumentjpaRepo documentRepositoryJpa;
//
//    @Override
//    public List<DocumentDTO> findAllDocuments() {
//        // Charger toutes les entités Document depuis la base de données
//        List<DocumentEntity> documents = documentRepositoryJpa.findAll();
//
//        // Convertir les entités en DTO pour les retourner
//        return documents.stream()
//            .map(document -> new DocumentDTO(
//                document.getId(),
//                document.getName(),
//                document.getDescription(),
//                document.getStatus(),
//                document.getMetadata().stream()
//                    .map(metaData -> new MetaDataDTO(metaData.getKey(), metaData.getValue()))
//                    .collect(Collectors.toList()),
//                document.getCreationDate(),
//                document.getModificationDate(),
//                null,
//                null
//            ))
//            .collect(Collectors.toList());
//    }
//
//    @Override
//    public void saveDocument(DocumentDTO documentDTO) {
//
//        DocumentEntity document = new DocumentEntity();
//
//        document.setName(documentDTO.getName());
//        document.setDescription(documentDTO.getDescription());
//        document.setStatus(documentDTO.getStatus());
//        document.setCreationDate(documentDTO.getCreationDate());
//        document.setModificationDate(documentDTO.getModificationDate());
//        document.setCreatedBy(documentDTO.getCreatedBy().getEmail());  // Assuming AdminUser has an `email` field
//        document.setModifiedBy(documentDTO.getModifiedBy().getEmail());
//
//
//        List<MetaDataEntity> metadataList = documentDTO.getMetadata().stream()
//            .map(metadataDTO -> new MetaDataEntity(null, document, metadataDTO.getKey(), metadataDTO.getValue()))
//            .collect(Collectors.toList());
//        document.setMetadata(metadataList);
//
//        documentRepositoryJpa.save(document);
//    }
//}


package com.socgen.unibank.services.autotest.gateways.outbound.persistence;

import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.DocumentEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.DocumentjpaRepo;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.MetaDataEntity;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.FolderDTO;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
@AllArgsConstructor
public class DocumentRepoImpl implements DocumentRepository {

    private final DocumentjpaRepo documentRepositoryJpa;

    @Override
    public List<DocumentDTO> findAllDocuments() {
        // Charger toutes les entités Document depuis la base de données
        List<DocumentEntity> documents = documentRepositoryJpa.findAll();

        // Convertir les entités en DTO pour les retourner
        return documents.stream()
            .map(document -> new DocumentDTO(
                document.getId(),
                document.getName(),
                document.getDescription(),
                document.getStatus(),
                document.getMetadata().stream()
                    .map(metaData -> new MetaDataDTO(metaData.getKey(), metaData.getValue()))
                    .collect(Collectors.toList()),
                document.getCreationDate(),
                document.getModificationDate(),
                null, // Assuming createdBy and modifiedBy will be set later
                null, // Assuming createdBy and modifiedBy will be set later
                document.getFolder() != null ? new FolderDTO(
                    document.getFolder().getId(),
                    document.getFolder().getName(),
                    document.getFolder().getParentFolder() != null ? document.getFolder().getParentFolder().getId() : null,
                    document.getFolder().getCreationDate(),
                    document.getFolder().getModificationDate(),
                    document.getFolder().getCreatedBy(),
                    document.getFolder().getModifiedBy(),
                    null, // Assuming documents and subfolders are not needed here
                    null  // Assuming documents and subfolders are not needed here
                ) : null,
                document.getFilePath(),
                document.getFileName()

            ))
            .collect(Collectors.toList());
    }

    @Override
    public DocumentDTO saveDocument(DocumentDTO documentDTO) {
        DocumentEntity document = new DocumentEntity();
        document.setName(documentDTO.getName());
        document.setDescription(documentDTO.getDescription());
        document.setStatus(documentDTO.getStatus());
        document.setCreationDate(documentDTO.getCreationDate());
        document.setModificationDate(documentDTO.getModificationDate());
        document.setCreatedBy(documentDTO.getCreatedBy().getEmail());  // Assuming AdminUser has an `email` field
        document.setModifiedBy(documentDTO.getModifiedBy().getEmail());

        if (documentDTO.getFolder() != null) {
            FolderEntity folderEntity = new FolderEntity();
            folderEntity.setId(documentDTO.getFolder().getId());
            document.setFolder(folderEntity);
        }

        List<MetaDataEntity> metadataList = documentDTO.getMetadata().stream()
            .map(metadataDTO -> new MetaDataEntity(null, document, metadataDTO.getKey(), metadataDTO.getValue()))
            .collect(Collectors.toList());
        document.setMetadata(metadataList);

        documentRepositoryJpa.save(document);
        return documentDTO;
    }
}


