Voici ma logique de Code Pour créer un Folder ::
FolderDTO ::
package com.socgen.unibank.services.autotest.model.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FolderDTO {
    private Long id;
    private String name;
    private Long parentFolderId; // ID du dossier parent pour gérer les hiérarchies
    private Date creationDate;
    private Date modificationDate;
    private String createdBy;
    private String modifiedBy;
    private List<DocumentDTO> documents;
    private List<FolderDTO> subFolders;
}

package com.socgen.unibank.services.autotest.model.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateFolderRequest {
    private String name;
    private Long parentFolderId;
    private String createdBy;
}

package com.socgen.unibank.services.autotest.model.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GetFolderRequest {
    private Long folderId;
}


Mes UseCases ::
package com.socgen.unibank.services.autotest.model.usecases;

import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.CreateFolderRequest;
import com.socgen.unibank.services.autotest.model.model.FolderDTO;

public interface CreateFolder {
    FolderDTO handle(CreateFolderRequest input, RequestContext context);
}

package com.socgen.unibank.services.autotest.model.usecases;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.FolderDTO;
import com.socgen.unibank.services.autotest.model.model.GetFolderRequest;

import java.util.List;

public interface GetFolder {
    List<FolderDTO> handle(GetFolderRequest input, RequestContext context);
}

Mon Api ::

    @Operation
        (summary = "Get list of folders",
            parameters = {
                @Parameter(ref = "entityIdHeader", required = true),

            }
        )
    @GetMapping("/folders")
    @Override
    List<FolderDTO> handle(GetFolderRequest input, @ModelAttribute RequestContext ctx);

    @Operation(
        summary = "Create a new folder",
        parameters = {
            @Parameter(ref = "entityIdHeader", required = true),

        }
    )
    @PostMapping("/folder")
    @Override
    FolderDTO handle(@RequestBody CreateFolderRequest input, @ModelAttribute RequestContext ctx);


}


Mon implémentation ::
package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.platform.models.RequestContext;

import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
import com.socgen.unibank.services.autotest.model.model.CreateFolderRequest;
import com.socgen.unibank.services.autotest.model.model.FolderDTO;
import com.socgen.unibank.services.autotest.model.usecases.CreateFolder;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Date;

@AllArgsConstructor
@Service
public class CreateFolderImpl implements CreateFolder {

    private final FolderRepository folderRepository;

    @Override
    public FolderDTO handle(CreateFolderRequest input, RequestContext context) {
        FolderEntity folderEntity = new FolderEntity();
        folderEntity.setName(input.getName());
        folderEntity.setCreatedBy(input.getCreatedBy());
        folderEntity.setCreationDate(new Date());
        folderEntity.setModificationDate(new Date());

        // Définir le dossier parent, si disponible
        if (input.getParentFolderId() != null) {
            FolderEntity parentFolder = folderRepository.findById(input.getParentFolderId())
                .orElseThrow(() -> new IllegalArgumentException("Parent folder not found"));
            folderEntity.setParentFolder(parentFolder);
        }

        FolderEntity savedFolder = folderRepository.save(folderEntity);
        return new FolderDTO(
            savedFolder.getId(),
            savedFolder.getName(),
            savedFolder.getParentFolder() != null ? savedFolder.getParentFolder().getId() : null,
            savedFolder.getCreationDate(),
            savedFolder.getModificationDate(),
            savedFolder.getCreatedBy(),
            savedFolder.getModifiedBy(),
            null,
            null
        );
    }
}


package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderEntity;
import com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa.FolderRepository;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.FolderDTO;
import com.socgen.unibank.services.autotest.model.model.GetFolderRequest;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import com.socgen.unibank.services.autotest.model.usecases.GetFolder;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@AllArgsConstructor
@Service
public class GetFolderImpl implements GetFolder {

    private final FolderRepository folderRepository;

    @Override
    public List<FolderDTO> handle(GetFolderRequest input, RequestContext context) {
        List<FolderEntity> folders = input.getFolderId() != null
            ? List.of(folderRepository.findById(input.getFolderId()).orElseThrow(() -> new IllegalArgumentException("Folder not found")))
            : folderRepository.findAll();

        return folders.stream()
            .map(folder -> new FolderDTO(
                folder.getId(),
                folder.getName(),
                folder.getParentFolder() != null ? folder.getParentFolder().getId() : null,
                folder.getCreationDate(),
                folder.getModificationDate(),
                folder.getCreatedBy(),
                folder.getModifiedBy(),
                folder.getDocuments() != null ? folder.getDocuments().stream() // Conversion de documents liés
                    .map(document -> new DocumentDTO(
                        document.getId(),
                        document.getName(),
                        document.getDescription(),
                        document.getStatus(),
                        document.getMetadata() != null ? document.getMetadata().stream()
                            .map(meta -> new MetaDataDTO(
                                meta.getKey(),
                                meta.getValue()
                            )).collect(Collectors.toList()) : null,
                        document.getCreationDate(),
                        document.getModificationDate(),
                        null,
                        null
                    )).collect(Collectors.toList()) : null,
                folder.getSubFolders() != null ? folder.getSubFolders().stream() // Conversion de sous-dossiers
                    .map(subFolder -> new FolderDTO(
                        subFolder.getId(),
                        subFolder.getName(),
                        subFolder.getParentFolder() != null ? subFolder.getParentFolder().getId() : null,
                        subFolder.getCreationDate(),
                        subFolder.getModificationDate(),
                        subFolder.getCreatedBy(),
                        subFolder.getModifiedBy(),
                        null, // Assuming sub-folder documents are not needed here
                        null  // Assuming sub-folder sub-folders are not needed here
                    )).collect(Collectors.toList()) : null
            ))
            .collect(Collectors.toList());
    }
}


Entité ::
package com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;

@Entity
@Table(name = "folder")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FolderEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @ManyToOne
    @JoinColumn(name = "parent_folder_id")
    private FolderEntity parentFolder;

    @OneToMany(mappedBy = "parentFolder", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<FolderEntity> subFolders;

    @OneToMany(mappedBy = "folder", cascade = CascadeType.ALL)
    private List<DocumentEntity> documents;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(nullable = false)
    private Date creationDate;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(nullable = false)
    private Date modificationDate;

    @Column(nullable = false)
    private String createdBy;

    @Column(nullable = false)
    private String modifiedBy;
}


package com.socgen.unibank.services.autotest.gateways.outbound.persistence.jpa;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FolderRepository extends JpaRepository<FolderEntity, Long> {}


<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.8.xsd">

    <changeSet id="4" author="Ousmane">
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

        <addForeignKeyConstraint baseColumnNames="parent_folder_id"
                                 baseTableName="folder"
                                 referencedColumnNames="id"
                                 referencedTableName="folder"
                                 constraintName="fk_folder_parent"/>
    </changeSet>
</databaseChangeLog>


Quand je teste sur swagger ::

{
  "name": "Test",
  "parentFolderId": 1,
  "createdBy": "usmane"
}

Voici mon erreur ::
2025-03-10T10:16:49.535Z ERROR [unibank-service-auto-test,,] 22088 --- [nio-8082-exec-7] s.c.w.RestResponseEntityExceptionHandler : 
java.lang.reflect.UndeclaredThrowableException
	at jdk.proxy2/jdk.proxy2.$Proxy223.handle(Unknown Source)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:77)
	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.base/java.lang.reflect.Method.invoke(Method.java:569)
	at org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:205)
	at org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:150)
	at org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:118)
	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:884)
	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:797)
	at org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)
	at org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1081)
	at org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:974)
	at org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1011)
	at org.springframework.web.servlet.FrameworkServlet.doPost(FrameworkServlet.java:914)
	at jakarta.servlet.http.HttpServlet.service(HttpServlet.java:590)
	at org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)
	at jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:205)
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:149)
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:174)
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:149)
	at org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231)
	at org.springframework.security.web.ObservationFilterChainDecorator$FilterObservation$SimpleFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:426)
	at org.springframework.security.web.ObservationFilterChainDecorator$AroundFilterObservation$SimpleAroundFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:287)
	at org.springframework.security.web.ObservationFilterChainDecorator.lambda$wrapSecured$0(ObservationFilterChainDecorator.java:80)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:126)
	at org.springframework.security.web.access.intercept.AuthorizationFilter.doFilter(AuthorizationFilter.java:100)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:126)
	at org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:120)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:131)
	at org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:85)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at org.springframework.security.web.authentication.AnonymousAuthenticationFilter.doFilter(AnonymousAuthenticationFilter.java:100)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at org.springframework.security.web.servletapi.SecurityContextHolderAwareRequestFilter.doFilter(SecurityContextHolderAwareRequestFilter.java:179)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at org.springframework.security.web.savedrequest.RequestCacheAwareFilter.doFilter(RequestCacheAwareFilter.java:63)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:187)
	at org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:174)
	at org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:135)
	at com.socgen.unibank.platform.springboot.config.web.RequestFilter.doFilterInternal(RequestFilter.java:131)
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)
	...
Caused by: com.socgen.unibank.platform.exceptions.TechnicalException: MISSING_USECASE_HANDLE
	at com.socgen.unibank.platform.springboot.config.UseCaseMapping.handle(UseCaseMapping.java:43)
	at com.socgen.unibank.platform.springboot.config.web.ControllersConfig.lambda$configureEndpoints$1(ControllersConfig.java:192)
