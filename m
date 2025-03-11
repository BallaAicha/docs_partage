Pour ce code ::
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
            String objectName = generateObjectName(file.getOriginalFilename(), context);

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

    private String generateObjectName(String originalFilename, RequestContext context) {
        return String.format("documents/%s/%s/%s_%s",
            context.getEntityId().get().name(),
            //context.getUsername(),
            UUID.randomUUID().toString(),
            originalFilename
        );
    }
}


Quand je upload un fichier pdf je vois cette erreur :
2025-03-11T13:27:29.176Z ERROR [unibank-service-auto-test,,] 14672 --- [nio-8082-exec-9] s.c.w.RestResponseEntityExceptionHandler :  Error uploading document: Format specifier '%s'
2025-03-11T13:27:29.179Z ERROR [unibank-service-auto-test,,] 14672 --- [nio-8082-exec-9] s.c.w.RestResponseEntityExceptionHandler : 
java.lang.IllegalArgumentException:  Error uploading document: Format specifier '%s'
	at com.socgen.unibank.services.autotest.core.usecases.DocumentUploadHelper.uploadDocument(DocumentUploadHelper.java:68)
	at com.socgen.unibank.services.autotest.core.usecases.DocumentController.uploadDocument(DocumentController.java:47)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	...
	at com.socgen.unibank.platform.springboot.config.web.RequestFilter.doFilterInternal(RequestFilter.java:131)
	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)
	...
