Voici mes parties de Code ::
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

    @Column(name = "file_path")
    private String filePath;

    @Column(name = "file_name")
    private String fileName;


}


package com.socgen.unibank.services.autotest.model.model;
import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.domain.base.DocumentStatus;
import com.socgen.unibank.platform.domain.Domain;
import com.socgen.unibank.platform.domain.URN;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.web.multipart.MultipartFile;

import java.util.Date;
import java.util.List;
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentDTO {

    private Long documentId;
   private String name;
   private String description;
   private DocumentStatus status;
   private List<MetaDataDTO> metadata;
    private Date creationDate;
    private Date modificationDate;
    private AdminUser createdBy;
    private AdminUser modifiedBy;
    private FolderDTO folder;

    private String filePath;
    private String fileName;

  //  private MultipartFile file;

}


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
            String objectName = generateObjectName(file.getOriginalFilename());

            // Upload to S3
            s3Client.upload(
                    file.getInputStream(),
                    objectName,
                    file.getContentType()
            );

            // Create document record
            DocumentDTO newDocument = createDocumentDTO(input, file, objectName, context);

            // Set folder if provided
            if (input.getFolderId() != null) {
                FolderEntity folder = folderRepository.findById(input.getFolderId())
                        .orElseThrow(() -> new TechnicalException("FOLDER_NOT_FOUND", "Folder not found with ID: " + input.getFolderId()));
                newDocument.setFolder(EntityToDTOConverter.convertFolderEntityToDTO(folder));
            }

            return documentRepository.saveDocument(newDocument);

        } catch (Exception e) {
            log.error("Error uploading document", e);

            throw new IllegalArgumentException(" Error uploading document: " + e.getMessage());

        }
    }

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is null or empty");
        }

        if (!file.getContentType().equals("application/pdf")) {
            throw new IllegalArgumentException("Invalid file type Only PDF files are allowed");
        }
    }

    private DocumentDTO createDocumentDTO(CreateDocumentEntryRequest input, MultipartFile file, String objectName, RequestContext context) {
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
        newDocument.setFilePath(objectName);
        newDocument.setFileName(file.getOriginalFilename());
        return newDocument;
    }

    private String generateObjectName(String originalFilename) {
        return String.format("documents/%s_%s",
                UUID.randomUUID().toString(),
                originalFilename
        );
    }
}

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
                <constraints nullable="false"/>
            </column>
            <column name="file_name" type="VARCHAR(255)">
                <constraints nullable="false"/>
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





Voici mon erreur quand je teste ::
2025-03-11T13:42:18.642Z  WARN [unibank-service-auto-test,,] 20736 --- [nio-8082-exec-7] o.h.engine.jdbc.spi.SqlExceptionHelper   : SQL Error: 23502, SQLState: 23502
2025-03-11T13:42:18.643Z ERROR [unibank-service-auto-test,,] 20736 --- [nio-8082-exec-7] o.h.engine.jdbc.spi.SqlExceptionHelper   : NULL non permis pour la colonne "file_path"
NULL not allowed for column "file_path"; SQL statement:
insert into "document" ("created_by", "creation_date", "description", "file_name", "file_path", "folder_id", "modification_date", "modified_by", "name", "status") values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) [23502-214]
2025-03-11T13:42:18.676Z ERROR [unibank-service-auto-test,,] 20736 --- [nio-8082-exec-7] c.s.u.s.a.c.u.DocumentUploadHelper       : Error uploading document

org.springframework.dao.DataIntegrityViolationException: could not execute statement; SQL [n/a]; constraint [null]
	at org.springframework.orm.jpa.vendor.HibernateJpaDialect.convertHibernateAccessException(HibernateJpaDialect.java:269) ~[spring-orm-6.0.12.jar:6.0.12]
	at org.springframework.orm.jpa.vendor.HibernateJpaDialect.translateExceptionIfPossible(HibernateJpaDialect.java:232) ~[spring-orm-6.0.12.jar:6.0.12]
	at org.springframework.orm.jpa.AbstractEntityManagerFactoryBean.translateExceptionIfPossible(AbstractEntityManagerFactoryBean.java:550) ~[spring-orm-6.0.12.jar:6.0.12]
	at org.springframework.dao.support.ChainedPersistenceExceptionTranslator.translateExceptionIfPossible(ChainedPersistenceExceptionTranslator.java:61) ~[spring-tx-6.0.12.jar:6.0.12]
	at org.springframework.dao.support.DataAccessUtils.translateIfNecessary(DataAccessUtils.java:243) ~[spring-tx-6.0.12.jar:6.0.12]
	at org.springframework.dao.support.PersistenceExceptionTranslationInterceptor.invoke(PersistenceExceptionTranslationInterceptor.java:152) ~[spring-tx-6.0.12.jar:6.0.12]
	at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184) ~[spring-aop-6.0.12.jar:6.0.12]
	at org.springframework.data.jpa.repository.support.CrudMethodMetadataPostProcessor$CrudMethodMetadataPopulatingMethodInterceptor.invoke(CrudMethodMetadataPostProcessor.java:164) ~[spring-data-jpa-3.0.10.jar:3.0.10]
	at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184) ~[spring-aop-6.0.12.jar:6.0.12]
	at org.springframework.aop.interceptor.ExposeInvocationInterceptor.invoke(ExposeInvocationInterceptor.java:97) ~[spring-aop-6.0.12.jar:6.0.12]
	at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184) ~[spring-aop-6.0.12.jar:6.0.12]
	at org.springframework.aop.framework.JdkDynamicAopProxy.invoke(JdkDynamicAopProxy.java:244) ~[spring-aop-6.0.12.jar:6.0.12]
	at jdk.proxy2/jdk.proxy2.$Proxy200.save(Unknown Source) ~[na:na]
	at com.socgen.unibank.services.autotest.gateways.outbound.persistence.DocumentRepoImpl.saveDocument(DocumentRepoImpl.java:209) ~[main/:na]
	at com.socgen.unibank.services.autotest.core.usecases.DocumentUploadHelper.uploadDocument(DocumentUploadHelper.java:174) ~[main/:na]
	at com.socgen.unibank.services.autotest.core.usecases.DocumentController.uploadDocument(DocumentController.java:47) ~[main/:na]
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~[na:na]
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:77) ~[na:na]
	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:na]
	at java.base/java.lang.reflect.Method.invoke(Method.java:569) ~[na:na]
	at org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:205) ~[spring-web-6.0.12.jar:6.0.12]
	at org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:150) ~[spring-web-6.0.12.jar:6.0.12]
	at org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:118) ~[spring-webmvc-6.0.12.jar:6.0.12]
	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:884) ~[spring-webmvc-6.0.12.jar:6.0.12]
	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:797) ~[spring-webmvc-6.0.12.jar:6.0.12]
	at org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87) ~[spring-webmvc-6.0.12.jar:6.0.12]
	at org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1081) ~[spring-webmvc-6.0.12.jar:6.0.12]
	at org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:974) ~[spring-webmvc-6.0.12.jar:6.0.12]
	at org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1011) ~[spring-webmvc-6.0.12.jar:6.0.12]
	at org.springframework.web.servlet.FrameworkServlet.doPost(FrameworkServlet.java:914) ~[spring-webmvc-6.0.12.jar:6.0.12]
	at jakarta.servlet.http.HttpServlet.service(HttpServlet.java:590) ~[tomcat-embed-core-10.1.13.jar:6.0]
	at org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885) ~[spring-webmvc-6.0.12.jar:6.0.12]
	at jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658) ~[tomcat-embed-core-10.1.13.jar:6.0]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:205) ~[tomcat-embed-core-10.1.13.jar:10.1.13]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:149) ~[tomcat-embed-core-10.1.13.jar:10.1.13]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110) ~[spring-web-6.0.12.jar:6.0.12]
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:174) ~[tomcat-embed-core-10.1.13.jar:10.1.13]
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:149) ~[tomcat-embed-core-10.1.13.jar:10.1.13]
	at org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$FilterObservation$SimpleFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:426) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$AroundFilterObservation$SimpleAroundFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:287) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator.lambda$wrapSecured$0(ObservationFilterChainDecorator.java:80) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:126) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.access.intercept.AuthorizationFilter.doFilter(AuthorizationFilter.java:100) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:126) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:120) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:131) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:85) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.authentication.AnonymousAuthenticationFilter.doFilter(AnonymousAuthenticationFilter.java:100) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.servletapi.SecurityContextHolderAwareRequestFilter.doFilter(SecurityContextHolderAwareRequestFilter.java:179) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.savedrequest.RequestCacheAwareFilter.doFilter(RequestCacheAwareFilter.java:63) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at com.socgen.unibank.platform.springboot.config.web.RequestFilter.doFilterInternal(RequestFilter.java:131) ~[unibank-platform-springboot-3.2.85.jar:na]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116) ~[spring-web-6.0.12.jar:6.0.12]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.authentication.logout.LogoutFilter.doFilter(LogoutFilter.java:107) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.authentication.logout.LogoutFilter.doFilter(LogoutFilter.java:93) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.header.HeaderWriterFilter.doHeadersAfter(HeaderWriterFilter.java:90) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.header.HeaderWriterFilter.doFilterInternal(HeaderWriterFilter.java:75) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116) ~[spring-web-6.0.12.jar:6.0.12]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.context.SecurityContextHolderFilter.doFilter(SecurityContextHolderFilter.java:82) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.context.SecurityContextHolderFilter.doFilter(SecurityContextHolderFilter.java:69) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.context.request.async.WebAsyncManagerIntegrationFilter.doFilterInternal(WebAsyncManagerIntegrationFilter.java:62) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116) ~[spring-web-6.0.12.jar:6.0.12]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.session.DisableEncodeUrlFilter.doFilterInternal(DisableEncodeUrlFilter.java:42) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116) ~[spring-web-6.0.12.jar:6.0.12]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$AroundFilterObservation$SimpleAroundFilterObservation.lambda$wrap$0(ObservationFilterChainDecorator.java:270) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:171) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135) ~[spring-security-web-6.0.7.jar:6.0.7]
	at org.springframework.security.web.FilterChainProxy.doFilterInternal(FilterChainProxy.java:233) ~[spring-security-web-6.0.7.jar:6.0.7]
