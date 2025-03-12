Je veux changer ma conception de comment je gére les documents , en fait ce qu'il faut savoir est que je veux gérer  plusieurs version pour un Document .

Donc je dois créer maintenant des versions de document  , et tu dois toujours sauvegarder le nom du fichier upload (nom_fichier_upload_version) 
Exemple : Pour le Document Normes Dev ( je peux lui créer une version : norme_1.0.pdf , puis  norme_2.0.pdf ,  norme_3.0.pdf) , ce nom unique doit etre sauvegarder dans S3 avec le fichier upload , et dans la base de données le meme nom qui se trouve dans S3 (document_version) , ce qui va faciliter par exemple quand je veux lire ou télécharger une version du document Normes dev  depuis mon frontend il suffit de passer à S3 le nom du fichier que je veux lire car il est stocké dans la base de donnée

Voici ma partie de Code à adapter pour répondre à mes attentes , fais les corrections nécessaires  ::
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

    @Column(nullable = false, unique = true)
    private String name;

    @Column(nullable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DocumentStatus status;

    @OneToMany(cascade = CascadeType.ALL, mappedBy = "document", orphanRemoval = true, fetch = FetchType.EAGER)
    private List<MetaDataEntity> metadata;


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

    @ManyToOne
    @JoinColumn(name = "folder_id")
    private FolderEntity folder;

    @ManyToOne
    @JoinColumn(name = "parent_document_id")
    private DocumentEntity parentDocument;

    @OneToMany(mappedBy = "parentDocument")
    private List<DocumentEntity> childDocuments;

    @OneToMany(mappedBy = "document", cascade = CascadeType.ALL)
    private List<DocumentVersionEntity> versions;


}









package com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Entity
@Table(name = "document_version")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentVersionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "document_id", nullable = false)
    private DocumentEntity document;

    @Column(nullable = false)
    private Integer versionNumber;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String description;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "creation_date", nullable = false)
    private Date creationDate;

    @Column(nullable = false)
    private String createdBy;
}





j'ai mal géré ma logique ici , il répond pas à mes besoins , adapte le car c'est un version d'un document qu'on doit créer ::
package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.core.usecases.DocumentUploadHelper;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import io.leangen.graphql.annotations.GraphQLRootContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/documents")
public class DocumentController {

    @Autowired
    private DocumentUploadHelper documentUploadHelper;

    @Operation(
        summary = "Upload a new document with metadata",
        parameters = {
            @Parameter(ref = "entityIdHeader", required = true)
        }
    )
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public DocumentDTO uploadDocument(
        @RequestParam("file") MultipartFile file,
        @RequestParam("name") String name,
        @RequestParam("description") String description,
        @RequestParam(value = "metadata", required = false) Map<String, String> metadata,
        @RequestParam(value = "folderId", required = false) Long folderId,
        @ModelAttribute @GraphQLRootContext RequestContext context
    ) {
        CreateDocumentEntryRequest request = new CreateDocumentEntryRequest();
        request.setName(name);
        request.setDescription(description);
        request.setMetadata(metadata);
        request.setFolderId(folderId);

        return documentUploadHelper.uploadDocument(file, request, context);
    }
}


Adapte ici aussi pour qu'il s'adapte avec :

//package com.socgen.unibank.services.autotest.core.usecases;
//
//import com.socgen.unibank.domain.base.AdminUser;
//import com.socgen.unibank.domain.base.DocumentStatus;
//import com.socgen.unibank.platform.exceptions.TechnicalException;
//import com.socgen.unibank.platform.models.RequestContext;
//import com.socgen.unibank.platform.service.s3.ObjectStorageClient;
//import com.socgen.unibank.services.autotest.core.DocumentRepository;
//import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.EntityToDTOConverter;
//import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
//import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
//import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
//import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
//import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.beans.factory.annotation.Qualifier;
//import org.springframework.stereotype.Component;
//import org.springframework.web.multipart.MultipartFile;
//
//import java.util.ArrayList;
//import java.util.Date;
//import java.util.UUID;
//import java.util.stream.Collectors;
//
//@Component
//@Slf4j
//public class DocumentUploadHelper {
//
//    @Autowired
//    private DocumentRepository documentRepository;
//
//    @Autowired
//    private FolderRepository folderRepository;
//
//    @Autowired
//    @Qualifier("privateS3Client")
//    private ObjectStorageClient s3Client;
//
//    public DocumentDTO uploadDocument(MultipartFile file, CreateDocumentEntryRequest input, RequestContext context) {
//        validateFile(file);
//
//        try {
//            String objectName = generateObjectName(file.getOriginalFilename(), context);
//
//            // Upload to S3
//            s3Client.upload(
//                file.getInputStream(),
//                objectName,
//                file.getContentType()
//            );
//
//            // Create document record
//            DocumentDTO newDocument = createDocumentDTO(input, file, objectName, context);
//
//            // Set folder if provided
//            if (input.getFolderId() != null) {
//                FolderEntity folder = folderRepository.findById(input.getFolderId())
//                    .orElseThrow(() -> new TechnicalException("FOLDER_NOT_FOUND", "Folder not found with ID: " + input.getFolderId()));
//                newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
//            }
//
//            return documentRepository.saveDocument(newDocument);
//
//        } catch (Exception e) {
//            log.error("Error uploading document", e);
//
//            throw new IllegalArgumentException(" Error uploading document: " + e.getMessage());
//
//        }
//    }
//
//    private void validateFile(MultipartFile file) {
//        if (file == null || file.isEmpty()) {
//            throw new IllegalArgumentException("File is null or empty");
//        }
//
//        if (!file.getContentType().equals("application/pdf")) {
//            throw new IllegalArgumentException("Invalid file type Only PDF files are allowed");
//        }
//    }
//
//    private DocumentDTO createDocumentDTO(CreateDocumentEntryRequest input, MultipartFile file, String objectName, RequestContext context) {
//        DocumentDTO newDocument = new DocumentDTO();
//        newDocument.setName(input.getName());
//        newDocument.setDescription(input.getDescription());
//        newDocument.setStatus(DocumentStatus.CREATED);
//        newDocument.setMetadata(input.getMetadata() != null ?
//            input.getMetadata().entrySet().stream()
//                .map(entry -> new MetaDataDTO(entry.getKey(), entry.getValue()))
//                .collect(Collectors.toList()) :
//            new ArrayList<>());
//        newDocument.setCreationDate(new Date());
//        newDocument.setModificationDate(new Date());
//        newDocument.setCreatedBy(new AdminUser("usmane@gmail.com"));
//        newDocument.setModifiedBy(new AdminUser("usmane@gmail.com"));
//        newDocument.setFilePath(objectName);
//        newDocument.setFileName(file.getOriginalFilename());
//        return newDocument;
//    }
//
//    private String generateObjectName(String originalFilename, RequestContext context) {
//        return String.format("documents/%s/%s/%s_%s",
//            context.getEntityId().get().name(),
//            //context.getUsername(),
//            UUID.randomUUID().toString(),
//            originalFilename
//        );
//    }
//}

package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.domain.base.DocumentStatus;
import com.socgen.unibank.platform.exceptions.TechnicalException;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.platform.service.s3.ObjectStorageClient;
import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.EntityToDTOConverter;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.Date;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
@Slf4j
public class DocumentUploadHelper {

    @Autowired
    private DocumentRepository documentRepository;

    @Autowired
    private FolderRepository folderRepository;

    @Autowired
    @Qualifier("privateS3Client")
    private ObjectStorageClient s3Client;

    public DocumentDTO uploadDocument(MultipartFile file, CreateDocumentEntryRequest input, RequestContext context) {
        validateFile(file);

        try {
            // Générer le nom de l'objet avant l'upload
            String objectName = generateObjectName(file.getOriginalFilename());

            // Vérifier que objectName n'est pas null
            if (objectName == null || objectName.trim().isEmpty()) {
                throw new IllegalArgumentException("Generated object name is null or empty");
            }

            // Upload to S3
            s3Client.upload(
                    file.getInputStream(),
                    "documents-test",
                    objectName,
                    file.getContentType()
            );

            // Créer le document seulement après un upload réussi
            DocumentDTO newDocument = createDocumentDTO(input, file, objectName, context);

            // Set folder if provided
            if (input.getFolderId() != null) {
                FolderEntity folder = folderRepository.findById(input.getFolderId())
                        .orElseThrow(() -> new TechnicalException("FOLDER_NOT_FOUND", "Folder not found with ID: " + input.getFolderId()));
                newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
            }
            return documentRepository.saveDocument(newDocument);

        } catch (Exception e) {
            log.error("Error uploading document: {}", e.getMessage(), e);
            throw new IllegalArgumentException("Error uploading document: " + e.getMessage());
        }
    }

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is null or empty");
        }

        if (!file.getContentType().equals("application/pdf")) {
            throw new IllegalArgumentException("Invalid file type. Only PDF files are allowed");
        }
    }

    private DocumentDTO createDocumentDTO(CreateDocumentEntryRequest input, MultipartFile file, String objectName, RequestContext context) {
        if (objectName == null || objectName.trim().isEmpty()) {
            throw new IllegalArgumentException("Object name cannot be null or empty");
        }

        DocumentDTO newDocument = new DocumentDTO();
        newDocument.setName(input.getName());
        newDocument.setDescription(input.getDescription());
        newDocument.setStatus(DocumentStatus.CREATED);
        newDocument.setMetadata(input.getMetadata() != null ?
                input.getMetadata().entrySet().stream()
                        .map(entry -> new MetaDataDTO(entry.getKey(), entry.getValue()))
                        .collect(Collectors.toList()) :
                new ArrayList<>());
        newDocument.setCreationDate(new Date());
        newDocument.setModificationDate(new Date());
        newDocument.setCreatedBy(new AdminUser("usmane@gmail.com"));
        newDocument.setModifiedBy(new AdminUser("usmane@gmail.com"));


        newDocument.setFilePath("/soksnsgsvsvsggs");
        newDocument.setFileName("test");

        return newDocument;
    }

    private String generateObjectName(String originalFilename) {
        if (originalFilename == null || originalFilename.trim().isEmpty()) {
            throw new IllegalArgumentException("Original filename cannot be null or empty");
        }

        return String.format("documents/%s_%s",
                UUID.randomUUID().toString(),
                originalFilename
        );
    }
}



Refais aussi ma migration avec la bonne logique :
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.8.xsd">

    <!-- ChangeSet for Folder table -->
    <changeSet id="20231001-1" author="developer">
        <createTable tableName="folder">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="name" type="VARCHAR(255)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="parent_folder_id" type="BIGINT"/>
            <column name="creation_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="modification_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="created_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="modified_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="folder"
            baseColumnNames="parent_folder_id"
            referencedTableName="folder"
            referencedColumnNames="id"
            constraintName="fk_folder_parent"/>
    </changeSet>

    <!-- ChangeSet for Document table -->
    <changeSet id="20231001-2" author="developer">
        <createTable tableName="document">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="name" type="VARCHAR(255)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="description" type="VARCHAR(512)">
                <constraints nullable="false"/>
            </column>
            <column name="status" type="VARCHAR(50)">
                <constraints nullable="false"/>
            </column>
            <column name="folder_id" type="BIGINT"/>
            <column name="creation_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="modification_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="created_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="modified_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="file_path" type="VARCHAR(512)">
                <constraints nullable="true"/>
            </column>
            <column name="file_name" type="VARCHAR(255)">
                <constraints nullable="true"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="document"
            baseColumnNames="folder_id"
            referencedTableName="folder"
            referencedColumnNames="id"
            constraintName="fk_document_folder"/>
    </changeSet>

    <!-- ChangeSet for Metadata table -->
    <changeSet id="20231001-3" author="developer">
        <createTable tableName="metadata">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="document_id" type="BIGINT">
                <constraints nullable="false"/>
            </column>
            <column name="key" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="value" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="metadata"
            baseColumnNames="document_id"
            referencedTableName="document"
            referencedColumnNames="id"
            constraintName="fk_metadata_document"/>
    </changeSet>

    <!-- ChangeSet for DocumentVersion table -->
    <changeSet id="20231001-4" author="developer">
        <createTable tableName="document_version">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true"/>
            </column>
            <column name="document_id" type="BIGINT">
                <constraints nullable="false"/>
            </column>
            <column name="version_number" type="INT">
                <constraints nullable="false"/>
            </column>
            <column name="name" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="description" type="VARCHAR(512)">
                <constraints nullable="false"/>
            </column>
            <column name="creation_date" type="TIMESTAMP">
                <constraints nullable="false"/>
            </column>
            <column name="created_by" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>

        <addForeignKeyConstraint
            baseTableName="document_version"
            baseColumnNames="document_id"
            referencedTableName="document"
            referencedColumnNames="id"
            constraintName="fk_document_version_document"/>
    </changeSet>



</databaseChangeLog>

