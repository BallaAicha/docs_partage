Voici mes différentes parties de Code :
package com.socgen.unibank.services.autotest.model.model;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.domain.base.DocumentStatus;
import com.socgen.unibank.platform.domain.Domain;
import com.socgen.unibank.platform.domain.URN;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentDTO  implements Domain {
    private URN urn;
   private String name;
   private String description;
   private DocumentStatus status;
   private List<MetaDataDTO> metadata;
    private Date creationDate;
    private Date modificationDate;
    private AdminUser createdBy;
    private AdminUser modifiedBy;
}


package com.socgen.unibank.services.autotest.model.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MetaDataDTO {
    private String key;
    private String value;
}

package com.socgen.unibank.services.autotest.model.model;

public enum DocumentStatus {
    ACTIVE, INACTIVE
}

package com.socgen.unibank.services.autotest.model.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateDocumentEntryRequest {
    private String name;
    private String description;
    private Map<String, String> metadata;
    private List<String> tags;
}

package com.socgen.unibank.services.autotest.model.model;

import io.swagger.v3.oas.annotations.Hidden;

@Hidden

public class GetDocumentEntryListRequest {

}

Mes UseCases :
package com.socgen.unibank.services.autotest.model.usecases;
import com.socgen.unibank.platform.domain.Query;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.GetDocumentEntryListRequest;

import java.util.List;

public interface GetDocumentList  extends Query{
    List<DocumentDTO> handle(GetDocumentEntryListRequest input, RequestContext context);
}

package com.socgen.unibank.services.autotest.model.usecases;

import com.socgen.unibank.platform.domain.Command;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;

public interface CreateDocument  extends Command {
    DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context);
}

package com.socgen.unibank.services.autotest.model;


import com.socgen.unibank.platform.models.RequestContext;

import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.GetDocumentEntryListRequest;
import com.socgen.unibank.services.autotest.model.usecases.CreateDocument;
import com.socgen.unibank.services.autotest.model.usecases.GetDocumentList;
import io.leangen.graphql.annotations.GraphQLQuery;
import io.leangen.graphql.annotations.GraphQLRootContext;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.web.bind.annotation.RequestBody;
import io.swagger.v3.oas.annotations.tags.Tag;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;

@Tag(name = "Document Management")
@RequestMapping(name = "documents", produces = "application/json")
public interface DocumentAPI extends GetDocumentList, CreateDocument {

    @GetMapping("/documents")
    @GraphQLQuery(name = "documentEntries")
   // @RolesAllowed(Permissions.IS_GUEST)
    @Override
    List<DocumentDTO> handle(GetDocumentEntryListRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);


    @Operation(
        summary = "Create a new document"
//        parameters = {
//            @Parameter(ref = "entityIdHeader", required = true)
//        }
    )
    @PostMapping("/document")
    @GraphQLQuery(name = "createDocument")
    //@RolesAllowed(Permissions.IS_GUEST)
    @Override
    DocumentDTO handle(@RequestBody CreateDocumentEntryRequest input, @GraphQLRootContext @ModelAttribute RequestContext ctx);


}

Implementation des Usecases :
package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.domain.base.AdminUser;
import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.model.model.CreateDocumentEntryRequest;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.MetaDataDTO;
import com.socgen.unibank.services.autotest.model.usecases.CreateDocument;
import org.springframework.stereotype.Service;
import com.socgen.unibank.domain.base.DocumentStatus;
import java.util.Date;
import java.util.stream.Collectors;

@Service
public class CreateDocumentImpl implements CreateDocument {

    private final DocumentRepository documentRepository;

    public CreateDocumentImpl(DocumentRepository documentRepository) {
        this.documentRepository = documentRepository;
    }

    @Override
    public DocumentDTO handle(CreateDocumentEntryRequest input, RequestContext context) {
        DocumentDTO newDocument = new DocumentDTO();
        newDocument.setName(input.getName());
        newDocument.setDescription(input.getDescription());
        newDocument.setStatus(DocumentStatus.CREATED);
        newDocument.setMetadata(input.getMetadata().entrySet().stream()
            .map(entry -> new MetaDataDTO(entry.getKey(), entry.getValue()))
            .collect(Collectors.toList()));
        newDocument.setCreationDate(new Date());
        newDocument.setModificationDate(new Date());
        newDocument.setCreatedBy(new AdminUser("usmane@socgen.com"));
        newDocument.setModifiedBy(new AdminUser("usmane@socgen.com"));

        documentRepository.saveDocument(newDocument);
        return newDocument;
    }
}

package com.socgen.unibank.services.autotest.core.usecases;

import com.socgen.unibank.platform.models.RequestContext;
import com.socgen.unibank.services.autotest.core.DocumentRepository;
import com.socgen.unibank.services.autotest.model.model.DocumentDTO;
import com.socgen.unibank.services.autotest.model.model.GetDocumentEntryListRequest;
import com.socgen.unibank.services.autotest.model.usecases.GetDocumentList;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class GetDocumentListImpl implements GetDocumentList {
    private final DocumentRepository autoTestRepository;

    public GetDocumentListImpl(DocumentRepository autoTestRepository) {
        this.autoTestRepository = autoTestRepository;
    }

    @Override
    public List<DocumentDTO> handle(GetDocumentEntryListRequest input, RequestContext context) {
        List<DocumentDTO> entries = autoTestRepository.findAllDocuments();
        if (input != null) {
            entries = entries.stream()
                .sorted(Comparator.comparing(DocumentDTO::getCreationDate).reversed())
                .collect(Collectors.toList());
        }
        return entries;
    }
}

package com.socgen.unibank.services.autotest.core;

import com.socgen.unibank.services.autotest.model.model.DocumentDTO;

import java.util.List;
public interface DocumentRepository {
    List<DocumentDTO> findAllDocuments();

    void saveDocument(DocumentDTO document);
}


package com.socgen.unibank.services.autotest.gateways.outbound.persistence;

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

    @Override
    public List<DocumentDTO> findAllDocuments() {
        List<DocumentDTO> documents = new ArrayList<>();
        documents.add(new DocumentDTO(
            new URN(null),
            "Document 1",
            "Description of Document 1",
            DocumentStatus.CREATED,
            List.of(new MetaDataDTO("key1", "value1")),
            new Date(),
            new Date(),
            new AdminUser("creator1"),
            new AdminUser("modifier1")
        ));
        documents.add(new DocumentDTO(
            new URN(null),
            "Document 2",
            "Description of Document 2",
            DocumentStatus.CREATED,
            List.of(new MetaDataDTO("key2", "value2")),
            new Date(),
            new Date(),
            new AdminUser("creator2"),
            new AdminUser("modifier2")
        ));
        return documents;
    }

    @Override
    public void saveDocument(DocumentDTO document) {
        documents.add(document);
    }


}

Question :: Donne les entités Jpa correspondant et leur relation et leur Repository Respectif  , puis donne moi un changelog avec liquibase pour faire la migration des données.
je veux utiliser une base h2 pour tester  
